import numpy as np
import scipy.io
from tqdm import tqdm


def read_data(idx):
    f = scipy.io.loadmat('./data/raw/sB' + str(idx) + '.mat')
    return f['ptch']  # shape 64 * 64 * 1000


class DataSampler:
    def __init__(self, n=10000, p=0.5, range1=tuple(range(1, 11)), range2=tuple(range(1, 11)), seed=0):
        self.n = n
        self.p = p  # prob. for same pair
        self.range1 = range1  # sample range for img 1
        self.range2 = range2  # sample range for img 2
        self.range = tuple(set(self.range1 + self.range2))
        self.data = None
        self.img = None
        self.class1 = None
        self.class2 = None
        self.label = None
        self.seed = seed
        np.random.seed(seed)

    def load(self):
        self.data = {}
        for i in self.range:
            self.data[i] = read_data(i)

    def sample(self):
        self.img = []
        self.class1 = []
        self.class2 = []
        self.label = []
        for i in tqdm(range(self.n)):
            # same
            if np.random.rand() < self.p:
                cls = np.random.choice(self.range)
                idx = np.random.choice(1000, size=2, replace=False)
                img = self.data[cls][:, :, idx]
                self.img.append(img)
                self.class1.append(cls)
                self.class2.append(cls)
                self.label.append(0)
            # different
            else:
                while True:
                    cls1 = np.random.choice(self.range1)
                    cls2 = np.random.choice(self.range2)
                    if cls1 != cls2:
                        break
                idx1, idx2 = np.random.choice(1000), np.random.choice(1000)
                img1, img2 = self.data[cls1][:, :, idx1], self.data[cls2][:, :, idx2]
                img = np.stack([img1, img2], axis=-1)
                self.img.append(img)
                self.class1.append(cls1)
                self.class2.append(cls2)
                self.label.append(1)

        # save
        img = np.array(self.img)
        class1 = np.array(self.class1)
        class2 = np.array(self.class2)
        label = np.array(self.label)
        np.savez('./data/processed/2', img=img, class1=class1, class2=class2, label=label)


sampler = DataSampler(n=52000, p=0.5, range1=(1, 51), range2=(1, 51))
sampler.load()
sampler.sample()
