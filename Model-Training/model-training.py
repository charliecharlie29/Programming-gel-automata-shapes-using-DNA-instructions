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

# load mnist data
(X_train_mnist, y_train_mnist), (X_test_mnist, y_test_mnist) = mnist.load_data()

# load .npy data
X_train_strip = np.load(folder+"/X_train_strip_v{}.npy".format(ver_num))
X_test_strip = np.load(folder+"/X_test_strip_v{}.npy".format(ver_num))
y_train_strip = np.load(folder+"/y_train_strip_v{}.npy".format(ver_num))
y_test_strip = np.load(folder+"/y_test_strip_v{}.npy".format(ver_num))

X_train_mnist = X_train_mnist / 255; X_test_mnist = X_test_mnist / 255
X_train_mnist = X_train_mnist.astype(np.float32)
X_test_mnist = X_test_mnist.astype(np.float32)
X_train_strip = X_train_strip.astype(np.float32)
X_test_strip = X_test_strip.astype(np.float32)

X_train = np.concatenate((X_train_mnist, X_train_strip))
X_test = np.concatenate((X_test_mnist, X_test_strip))
X_train = X_train.reshape((X_train.shape[0], 28, 28, 1)).astype('float32')
X_test = X_test.reshape((X_test.shape[0], 28, 28, 1)).astype('float32')
y_train = np.concatenate((y_train_mnist, y_train_strip))
y_test = np.concatenate((y_test_mnist, y_test_strip))
y_train = np_utils.to_categorical(y_train)
y_test = np_utils.to_categorical(y_test)

# convolutional neural network
model = Sequential()
model.add(Conv2D(30, (5, 5), input_shape = (28, 28, 1), activation = 'relu'))
model.add(MaxPooling2D())
model.add(Conv2D(15, (3, 3), activation = 'relu'))
model.add(MaxPooling2D())
model.add(Dropout(0.2))
model.add(Flatten())
model.add(Dense(256, activation='relu'))
model.add(Dense(100, activation='relu'))
model.add(Dense(num_classes, activation = 'softmax'))
# Compile model
model.compile(loss = 'categorical_crossentropy', optimizer = 'adam', metrics = ['accuracy'])

filepath = "Deep_Learning_Classifier_v3.h5"

checkpoint = ModelCheckpoint(filepath, monitor = 'val_loss', verbose = 1, save_best_only = True, mode = 'min')
callbacks_list = [checkpoint]

history = model.fit(X_train, y_train,\
                    validation_data = (X_test, y_test), epochs = 20, batch_size = 200,\
                    callbacks = callbacks_list)