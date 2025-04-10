import cv2
import numpy as np

with open('vga_image.bin', 'rb') as file:
    binary_data = np.asanyarray(bytearray(file.read()))

new_data = np.reshape(binary_data, ((600,800,3)), order='C')

cv2.imwrite('color_img44.jpg', new_data)
