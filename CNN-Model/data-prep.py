import os
import numpy as np
import matplotlib.pyplot as plt

from keras.datasets import mnist
from keras.utils import np_utils
from keras.models import Sequential, load_model
from keras.layers import Dense, Dropout, Flatten
from keras.layers.convolutional import Conv2D, MaxPooling2D

from sklearn.model_selection import train_test_split

folder = "."
ver_num = 1

# read files and save imgname and label into files with [(imgname1, label1) ...]
files = [("/".join((folder,"digit{}".format(i),j)), i) for i in range(11) for j in os.listdir("/".join((folder,"digit{}".format(i)))) if ".DS" not in j]
X_strip = np.zeros(shape=(len(files), 28, 28))
y_strip = np.zeros(shape=(len(files)))
for i in range(len(files)):
    X_strip[i] = plt.imread(files[i][0])[:,:,0]; y_strip[i] = files[i][1]


X_train_strip, X_test_strip, y_train_strip, y_test_strip = train_test_split(X_strip, y_strip,\
                                                    test_size = 0.15, random_state = 89,\
                                                    stratify = y_strip, shuffle = True)

# Save to .npy files for loading
np.save(folder+"/X_train_strip_v{}.npy".format(ver_num), X_train_strip)
np.save(folder+"/X_test_strip_v{}.npy".format(ver_num), X_test_strip)
np.save(folder+"/y_train_strip_v{}.npy".format(ver_num), y_train_strip)
np.save(folder+"/y_test_strip_v{}.npy".format(ver_num), y_test_strip)
