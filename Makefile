I2C_MODE = RPI
I2C_LIBS = -lbcm2835

CFLAGS = -DSTANDALONE -D__STDC_CONSTANT_MACROS -D__STDC_LIMIT_MACROS \
		-DTARGET_POSIX -D_LINUX -DPIC -D_REENTRANT -D_LARGEFILE64_SOURCE \
		-D_FILE_OFFSET_BITS=64 -U_FORTIFY_SOURCE -DHAVE_LIBOPENMAX=2 -DOMX \
		-DOMX_SKIP64BIT -ftree-vectorize -pipe -DUSE_EXTERNAL_OMX \
		-DHAVE_LIBBCM_HOST -DUSE_EXTERNAL_LIBBCM_HOST -DUSE_VCHIQ_ARM -fPIC \
		-ftree-vectorize -pipe -fpermissive

LDFLAGS = -L/opt/vc/lib -lopenmaxil -lbcm_host -lvcos -lvchiq_arm -lpthread

INCLUDES = -I/opt/vc/include -I/opt/vc/include/interface/vcos/pthreads \
		-I/opt/vc/include/interface/vmcs_host/linux

all: examples

examples: test step fbuf interp video omxv

libMLX90640_API.so: functions/MLX90640_API.o functions/MLX90640_$(I2C_MODE)_I2C_Driver.o
	$(CXX) -fPIC -shared $^ -o $@ $(I2C_LIBS)

libMLX90640_API.a: functions/MLX90640_API.o functions/MLX90640_$(I2C_MODE)_I2C_Driver.o
	ar rcs $@ $^
	ranlib $@

functions/MLX90640_API.o functions/MLX90640_RPI_I2C_Driver.o functions/MLX90640_LINUX_I2C_Driver.o : CXXFLAGS+=-fPIC -I headers -shared $(I2C_LIBS)

examples/test.o examples/step.o examples/fbuf.o examples/interp.o examples/video.o : CXXFLAGS+=-std=c++11

examples/omxv.o : CXXFLAGS+=-std=c++11 $(INCLUDES) $(CFLAGS)

dump.o : CFLAGS+=-std=c++11 $(INCLUDES)

test step fbuf omxv interp video hotspot : CXXFLAGS+=-I. -std=c++11

examples/lib/interpolate.o : CC=$(CXX) -std=c++11

hotspot: examples/hotspot.o examples/lib/fb.o libMLX90640_API.a
	$(CXX) -L/home/pi/mlx90640-library $^ -o $@ $(I2C_LIBS)

test: examples/test.o libMLX90640_API.a
	$(CXX) -L/home/pi/mlx90640-library $^ -o $@ $(I2C_LIBS)

step: examples/step.o libMLX90640_API.a
	$(CXX) -L/home/pi/mlx90640-library $^ -o $@ $(I2C_LIBS)

fbuf: examples/fbuf.o examples/lib/fb.o libMLX90640_API.a
	$(CXX) -L/home/pi/mlx90640-library $^ -o $@ $(I2C_LIBS)

omxv: examples/omxv.o examples/lib/fb.o libMLX90640_API.a dump.o
	$(CXX) -L/home/pi/mlx90640-library $(LDFLAGS) $^ -o $@ $(I2C_LIBS)

interp: examples/interp.o examples/lib/interpolate.o examples/lib/fb.o libMLX90640_API.a
	$(CXX) -L/home/pi/mlx90640-library $^ -o $@ $(I2C_LIBS)

video: examples/video.o examples/lib/fb.o libMLX90640_API.a
	$(CXX) -L/home/pi/mlx90640-library $^ -o $@ $(I2C_LIBS) -lavcodec -lavutil -lavformat -lbcm2835

bcm2835-1.55.tar.gz:	
	wget http://www.airspayce.com/mikem/bcm2835/bcm2835-1.55.tar.gz

bcm2835-1.55: bcm2835-1.55.tar.gz
	tar xzvf bcm2835-1.55.tar.gz

bcm2835: bcm2835-1.55
	cd bcm2835-1.55; ./configure; make; sudo make install

clean:
	rm -f test step fbuf omxv interp video
	rm -f examples/*.o
	rm -f examples/lib/*.o
	rm -f functions/*.o
	rm -f *.o
	rm -f *.so
	rm -f test
	rm -f *.a
