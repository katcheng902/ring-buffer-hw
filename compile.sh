# Define p4 name
P4_NAME=opt_buffers
# Provide p4 path
P4_PATH=/root/ring-buffer/opt_buffers.p4

cd build
cmake ~/bf-sde-9.8.0/p4studio/ -DTOFINO=ON -DTOFINO2=OFF -DCMAKE_INSTALL_PREFIX=~/bf-sde-9.8.0/install -DCMAKE_MODULE_PATH=~/bf-sde-9.8.0/cmake \
	-DP4_NAME=$P4_NAME \
	-DP4_PATH=$P4_PATH \
	&& make $P4_NAME -j \
	&& make install
cd ..
