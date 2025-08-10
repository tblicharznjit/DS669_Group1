import numpy as np
import torch
import torch.nn as nn
import torch.optim
import torch.nn.functional as F
import copy

# gamma = 0.9
device = 'mps'


class DistributionalDQN(nn.Module):
    def __init__(self, state_dim, n_actions, ):
        super(DistributionalDQN, self).__init__()

        self.conv = nn.Sequential(
            nn.Linear(state_dim, 128),
            nn.ReLU(),
            nn.Linear(128, 128),
            nn.ReLU(),
        )
        self.fc_val = nn.Sequential(
            nn.Linear(128, 256),
            nn.ReLU(),
            nn.Linear(256, 1)
        )
        self.fc_adv = nn.Sequential(
            nn.Linear(128, 256),
            nn.ReLU(),
            nn.Linear(256, n_actions)
        )

    def forward(self, state):
        conv_out = self.conv(state)
        val = self.fc_val(conv_out)
        adv = self.fc_adv(conv_out)
        return val + adv - adv.mean(dim=1, keepdim=True)


class Dist_DQN:
    def __init__(self, state_dim=49, num_actions=25, device='cpu', gamma=0.999, tau=0.1):
        self.device = device
        self.Q = DistributionalDQN(state_dim, num_actions).to(device)
        self.Q_target = copy.deepcopy(self.Q)
        self.tau = tau
        self.gamma = gamma
        self.num_actions = num_actions
        self.optimizer = torch.optim.Adam(self.Q.parameters(), lr=0.0001)

    def train(self, batchs, epoch):
        state, next_state, action, next_action, reward, done, bloc_num, SOFAS = batchs
        batch_s = 128
        uids = np.unique(bloc_num)
        num_batch = len(uids) // batch_s + (1 if len(uids) % batch_s != 0 else 0)
        record_loss = []
        sum_q_loss = 0
        for batch_idx in range(num_batch):
            batch_uids = uids[batch_idx * batch_s: (batch_idx + 1) * batch_s]
            batch_user = np.isin(bloc_num, batch_uids)
            state_user = torch.FloatTensor(state[batch_user]).to(self.device)
            next_state_user = torch.FloatTensor(next_state[batch_user]).to(self.device)
            action_user = torch.LongTensor(action[batch_user]).to(self.device)
            next_action_user = torch.LongTensor(next_action[batch_user]).to(self.device)
            reward_user = torch.FloatTensor(reward[batch_user]).to(self.device)
            done_user = torch.FloatTensor(done[batch_user]).to(self.device)
            SOFAS_user = torch.FloatTensor(SOFAS[batch_user]).to(self.device)
            batch = (state_user, next_state_user, action_user, next_action_user, reward_user, done_user, SOFAS_user)
            loss = self.compute_loss(batch)
            sum_q_loss += loss.item()
            self.optimizer.zero_grad()
            loss.backward()
            self.optimizer.step()
            if batch_idx % 25 == 0:
                print(f'Epoch: {epoch}, Batch: {batch_idx}, Average Loss: {sum_q_loss / (batch_idx + 1)}')
                record_loss.append(sum_q_loss / (batch_idx + 1))
            if batch_idx % 100 == 0:
                self.polyak_target_update()
        return record_loss

    def polyak_target_update(self):
        for param, target_param in zip(self.Q.parameters(), self.Q_target.parameters()):
            target_param.data.copy_(self.tau * param.data + (1 - self.tau) * target_param.data)

    def compute_loss(self, batch):
        state, next_state, action, next_action, reward, done, SOFA = batch
        gamma = self.gamma
        end_multiplier = 1 - done
        batch_size = state.shape[0]
        range_batch = torch.arange(batch_size).long().to(self.device)
        log_Q_dist_prediction = self.Q(state)
        log_Q_dist_prediction1 = log_Q_dist_prediction[range_batch, action.squeeze()]
        q_eval4nex = self.Q(next_state)
        max_eval_next = torch.argmax(q_eval4nex, dim=1)
        with torch.no_grad():
            Q_dist_target = self.Q_target(next_state)
            Q_target = Q_dist_target.clone().detach()
        Q_dist_eval = Q_dist_target[range_batch, max_eval_next]
        max_target_next = torch.argmax(Q_dist_target, dim=1)
        Q_dist_tar = Q_dist_target[range_batch, max_target_next]
        Q_target_pro = F.softmax(Q_target, dim=1)
        pro1 = Q_target_pro[range_batch, max_eval_next]
        pro2 = Q_target_pro[range_batch, max_target_next]
        Q_dist_star = (pro1 / (pro1 + pro2)) * Q_dist_eval + (pro2 / (pro1 + pro2)) * Q_dist_tar
        log_Q_experience = Q_dist_target[range_batch, next_action.squeeze()]
        Q_experi = torch.where(SOFA < 4, log_Q_experience, Q_dist_star)
        targetQ1 = reward + (gamma * Q_experi * end_multiplier)
        return nn.SmoothL1Loss()(targetQ1, log_Q_dist_prediction1)

    def get_action(self, state):
        with torch.no_grad():
            state = torch.FloatTensor(state).to(self.device)
            Q_dist = self.Q(state)
            a_star = torch.argmax(Q_dist, dim=1)
            return a_star.cpu().numpy()