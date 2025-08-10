import numpy as np
import torch
import pickle
from ID3QNE_deepQnet import Dist_DQN

# ====== CONFIG ======
device = 'mps' if torch.mps.is_available() else 'cpu'
epochs = 100  # adjust for longer training

# ====== Load Real Patient Data ======
with open('requiredFile.pkl', 'rb') as f:
    MIMICtable = pickle.load(f)

X = MIMICtable['X']
Xnext = MIMICtable['Xnext']
Action = MIMICtable['Action']
ActionNext = MIMICtable['ActionNext']
Reward = MIMICtable['Reward']
Done = MIMICtable['Done']
Bloc = MIMICtable['Bloc']
SOFA = MIMICtable['SOFA']

# Convert to torch tensors
state = torch.FloatTensor(X).to(device)
next_state = torch.FloatTensor(Xnext).to(device)
action = torch.LongTensor(Action).to(device)
next_action = torch.LongTensor(ActionNext).view(-1, 1).to(device)  # ensure correct shape for indexing
reward = torch.FloatTensor(Reward).to(device)
done = torch.FloatTensor(Done).to(device)
bloc_num = Bloc
SOFAS = torch.FloatTensor(SOFA).to(device)  # ensure SOFA is a tensor for torch.where

batchs = (state, next_state, action, next_action, reward, done, bloc_num, SOFAS)

# ====== Set dimensions ======
state_dim = state.shape[1]
num_actions = 25

# ====== Initialize Model ======
model = Dist_DQN(state_dim=state_dim, num_actions=num_actions, device=device)

# ====== Training Loop ======
all_losses = []
for epoch in range(1, epochs + 1):
    epoch_loss = model.train(batchs, epoch)
    all_losses.append(epoch_loss)
    print(f'Epoch {epoch} completed.')

# ====== Save Model ======
torch.save(model.Q.state_dict(), 'wd3qne_trained_model_real.pth')
print('Model saved as wd3qne_trained_model_real.pth')

# ====== Save Loss Logs ======
np.save('wd3qne_losses_real.npy', all_losses)
print('Loss log saved as wd3qne_losses_real.npy')

