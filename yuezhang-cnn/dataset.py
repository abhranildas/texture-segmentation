import numpy as np
from torch.utils.data.dataset import Dataset


class TextureDiscriminationDataset(Dataset):
    def __init__(self, data_dir='./data/processed/1.npz', start=0, end=None, transforms=None):
        data = np.load(data_dir)
        self.img_pairs = data['img'][start:end]
        self.labels = data['label'][start:end]
        self.transforms = transforms

    def __getitem__(self, idx):
        img = self.img_pairs[idx]
        if self.transforms is not None:
            img = self.transforms(img)
        label = self.labels[idx]
        return img, label

    def __len__(self):
        return len(self.img_pairs)
