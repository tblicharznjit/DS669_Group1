import torch
import numpy as np
import warnings
import torch.nn.functional as F

warnings.filterwarnings("ignore")
device = 'mps' 


def do_eval(model, batchs, batch_size=128):
    (state, next_state, action, next_action, reward, done) = batchs
    Q_value = model.Q(state)
    agent_actions = torch.argmax(Q_value, dim=1)
    phy_actions = action
    Q_value_pro1 = F.softmax(Q_value)
    Q_value_pro_ind = torch.argmax(Q_value_pro1, dim=1)
    Q_value_pro_ind1 = range(len(Q_value_pro_ind))
    Q_value_pro = Q_value_pro1[Q_value_pro_ind1, Q_value_pro_ind]
    return Q_value, agent_actions, phy_actions, Q_value_pro


def do_test(model, Xtest, actionbloctest, bloctest, Y90, SOFA, reward_value, beat, directory='Q值'):
    bloc_max = max(bloctest)
    r = np.array([reward_value, -reward_value]).reshape(1, -1)
    r2 = r * (2 * (1 - Y90.reshape(-1, 1)) - 1)
    R3 = r2[:, 0]
    RNNstate = Xtest
    print('#### Generating test set trajectories ####')
    print(f"Input shapes: Xtest={Xtest.shape}, actionbloctest={actionbloctest.shape}, "
          f"bloctest={bloctest.shape}, Y90={Y90.shape}, SOFA={SOFA.shape}")
    statesize = int(RNNstate.shape[1])
    states = np.zeros((RNNstate.shape[0], statesize))
    actions = np.zeros((RNNstate.shape[0], 1), dtype=int)
    next_actions = np.zeros((RNNstate.shape[0], 1), dtype=int)
    rewards = np.zeros((RNNstate.shape[0], 1))
    next_states = np.zeros((RNNstate.shape[0], statesize))
    done_flags = np.zeros((RNNstate.shape[0], 1))
    bloc_num = np.zeros((RNNstate.shape[0], 1))
    blocnum1 = 1
    c = 0
    for i in range(RNNstate.shape[0] - 1):
        states[c] = RNNstate[i, :]
        actions[c] = actionbloctest[i]
        bloc_num[c] = blocnum1
        if (bloctest[i + 1] == 1):
            next_states1 = np.zeros(statesize)
            next_actions1 = -1
            done_flags1 = 1
            reward1 = -beat[0] * SOFA[i] + R3[blocnum1 - 1]
            blocnum1 += 1
        else:
            next_states1 = RNNstate[i + 1, :]
            next_actions1 = actionbloctest[i + 1]
            done_flags1 = 0
            reward1 = -beat[1] * (SOFA[i + 1] - SOFA[i])
        next_states[c] = next_states1
        next_actions[c] = next_actions1
        rewards[c] = reward1
        done_flags[c] = done_flags1
        c += 1
    states[c] = RNNstate[c, :]
    actions[c] = actionbloctest[c]
    bloc_num[c] = blocnum1
    next_states1 = np.zeros(statesize)
    next_actions1 = -1
    done_flags1 = 1
    reward1 = -beat[0] * SOFA[c] + R3[blocnum1 - 1]
    next_states[c] = next_states1
    next_actions[c] = next_actions1
    rewards[c] = reward1
    done_flags[c] = done_flags1
    c += 1
    bloc_num = bloc_num[:c, :]
    states = states[:c, :]
    next_states = next_states[:c, :]
    actions = actions[:c, :]
    next_actions = next_actions[:c, :]
    rewards = rewards[:c, :]
    done_flags = done_flags[:c, :]
    bloc_num = np.squeeze(bloc_num)
    actions = np.squeeze(actions)
    rewards = np.squeeze(rewards)
    done_flags = np.squeeze(done_flags)
    state = torch.FloatTensor(states).to(device)
    next_state = torch.FloatTensor(next_states).to(device)
    action = torch.LongTensor(actions).to(device)
    next_action = torch.LongTensor(next_actions).to(device)
    reward = torch.FloatTensor(rewards).to(device)
    done = torch.FloatTensor(done_flags).to(device)
    batchs = (state, next_state, action, next_action, reward, done, bloc_num)
    rec_phys_q = []
    rec_agent_q = []
    rec_agent_q_pro = []
    rec_phys_a = []
    rec_agent_a = []
    rec_sur = []
    rec_reward_user = []
    batch_s = 128
    uids = np.unique(bloc_num)
    num_batch = len(uids) // batch_s + (1 if len(uids) % batch_s != 0 else 0)
    for batch_idx in range(num_batch):
        batch_uids = uids[batch_idx * batch_s: (batch_idx + 1) * batch_s]
        batch_user = np.isin(bloc_num, batch_uids)
        state_user = state[batch_user, :]
        next_state_user = next_state[batch_user, :]
        action_user = action[batch_user]
        next_action_user = next_action[batch_user]
        reward_user = reward[batch_user]
        done_user = done[batch_user]
        patient_indices = bloc_num[batch_user] - 1
        sur_Y90 = Y90[patient_indices.astype(int)]
        batch = (state_user, next_state_user, action_user, next_action_user, reward_user, done_user)
        q_output, agent_actions, phys_actions, Q_value_pro = do_eval(model, batch)
        agent_q = q_output[range(len(q_output)), agent_actions]
        phys_q = q_output[range(len(q_output)), phys_actions]
        rec_agent_q.extend(agent_q.tolist())  
        rec_phys_q.extend(phys_q.tolist())   
        rec_agent_q_pro.extend(Q_value_pro.tolist())  
        rec_agent_a.extend(agent_actions.tolist())
        rec_phys_a.extend(phys_actions.tolist())
        rec_sur.extend(sur_Y90.tolist())
        rec_reward_user.extend(reward_user.cpu().numpy().tolist())
    np.save(f'{directory}/patient_survival_outcomes.npy', np.array(rec_sur))
    np.save(f'{directory}/dqn_agent_q_values.npy', np.array(rec_agent_q))
    np.save(f'{directory}/physician_q_values.npy', np.array(rec_phys_q))
    np.save(f'{directory}/step_rewards.npy', np.array(rec_reward_user))
    np.save(f'{directory}/dqn_agent_actions.npy', np.array(rec_agent_a))
    np.save(f'{directory}/physician_actions.npy', np.array(rec_phys_a))
    np.save(f'{directory}/dqn_agent_q_probs.npy', np.array(rec_agent_q_pro))
    return rec_agent_q, rec_phys_q, rec_agent_a, rec_phys_a, rec_sur, rec_reward_user, rec_agent_q_pro