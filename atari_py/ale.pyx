#from cpython cimport array
cimport numpy as np
import numpy as np
from libc.string cimport memcpy
#from cpython.ref cimport PyObject
from ale_bindings cimport ALEInterface as _ALEInterface
from ale_bindings cimport ALEState as _ALEState
from ale_bindings cimport ALEScreen, ALERAM, uInt8
from cython.operator cimport dereference as deref

from cpython.object cimport Py_EQ, Py_NE


# We need to initialize NumPy.
np.import_array()


cdef class ALEInterface(object)


cdef class ALEState(object):
    cdef _ALEState obj
    cdef ALEInterface ale  # hold reference to not be gc'd

    def __cinit__(self, ALEInterface ale):
        self.obj = ale.obj.cloneState()
        self.ale = ale

    cdef restore(self, ALEInterface ale):
        if self.ale is not self:
            raise ValueError('Can only restore state on the ale instance it yielded from')
        ale.obj.restoreState(self.obj)

    #def __dealloc__(self):
    #    del self.obj

    #def __eq__(self, other):
    #    return isinstance(other, type(self)) and self.obj.equals(other.obj)
    #
    #def __ne__(self, other):
    #    return not self.__eq__(other)
    #
    def __richcmp__(self, other, int op):
        if not isinstance(other, type(self)):
            return False

        if op == Py_EQ:
            return self.obj.equals(other.obj)
        elif op == Py_NE:
            return not self.obj.equals(other.obj)
        else:
            raise NotImplementedError

    @property
    def frame_number(self):
        return self.obj.getFrameNumber()

    @property
    def episode_frame_number(self):
        return self.obj.getEpisodeFrameNumber()


cdef class ALEInterface(object):
    cdef _ALEInterface obj

    def getString(self, key):
        return self.obj.getString(key)
    
    def getInt(self, key):
        return self.obj.getInt(key)
    
    def getBool(self, key):
        return self.obj.getBool(key)
    
    def getFloat(self, key):
        return self.obj.getFloat(key)
    
    def setString(self, key, value):
        self.obj.setString(key, value)
    
    def setInt(self, key, value):
        self.obj.setInt(key, value)
    
    def setBool(self, key, value):
        self.obj.setBool(key, value)
    
    def setFloat(self, key, value):
        self.obj.setFloat(key, value)
    
    def loadROM(self, rom_file):
        #self.obj.loadROM(six.b(rom_file))
        self.obj.loadROM(rom_file.encode('utf-8'))
        #self.obj.loadROM(rom_file)

    def act(self, action):
        return self.obj.act(int(action))
    
    def game_over(self):
        return self.obj.game_over()
    
    def reset_game(self):
        self.obj.reset_game()
    
    def getLegalActionSet(self):
        return self.obj.getLegalActionSet()
    #    act_size = self.obj.getLegalActionSize()
    #    act = np.zeros((act_size), dtype=np.intc)
    #    self.obj.getLegalActionSet(as_ctypes(act))
    #    return act
    #    return vector_to_numpy(ale->getLegalActionSet())

    def getMinimalActionSet(self):
        return self.obj.getMinimalActionSet()
    #    act_size = self.obj.getMinimalActionSize()
    #    act = np.zeros((act_size), dtype=np.intc)
    #    self.obj.getMinimalActionSet(as_ctypes(act))
    #    return act
    #    return vector_to_numpy(ale->getMinimalActionSet())

    def getFrameNumber(self):
        return self.obj.getFrameNumber()

    def lives(self):
        return self.obj.lives()

    def getEpisodeFrameNumber(self):
        return self.obj.getEpisodeFrameNumber()

    def getScreenDims(self):
        """Returns a tuple that contains (screen_width, screen_height)"""
        cdef const ALEScreen * screen = &self.obj.getScreen()
        return screen.width(), screen.height()

    def getScreen(self, screen_data=None):
        """This function fills screen_data with the RAW Pixel data
        screen_data MUST be a numpy array of uint8/int8. This could be initialized like so:
        screen_data = np.empty(w*h, dtype=np.uint8)
        Notice,  it must be width*height in size also
        If it is None,  then this function will initialize it
        Note: This is the raw pixel values from the atari,  before any RGB palette transformation takes place
        """
        '''
        int w = ale->getScreen().width();
        int h = ale->getScreen().height();
        pixel_t *ale_screen_data = (pixel_t *)ale->getScreen().getArray();
        memcpy(screen_data,ale_screen_data,w*h*sizeof(pixel_t));
        '''
        #cdef np.ndarray screen_data
        cdef const ALEScreen * screen = &self.obj.getScreen()
        cdef np.npy_intp shape[1]
        if screen_data is None:
            shape[0] = screen.width() * screen.height()
            # static assert NPY_UBYTE == pixel_t
            return np.PyArray_SimpleNewFromData(sizeof(shape), shape, np.NPY_UBYTE, screen.getArray())

        return screen_data

    def getScreenRGB(self, screen_data=None):
        """This function fills screen_data with the data in RGB format
        screen_data MUST be a numpy array of uint8. This can be initialized like so:
        screen_data = np.empty((height,width,3), dtype=np.uint8)
        If it is None,  then this function will initialize it.
        """
        '''
        size_t w = ale->getScreen().width();
        size_t h = ale->getScreen().height();
        size_t screen_size = w*h;
        pixel_t *ale_screen_data = ale->getScreen().getArray();
        
        for(int i = 0;i < w*h;i++){
            output_buffer[i] = rgb_palette[ale_screen_data[i]];
        }
        '''
        #cdef np.ndarray[np.NPY_UBYTE, ndim=3] screen_data
        cdef const ALEScreen * screen = &self.obj.getScreen()
        cdef np.npy_intp shape[3]
        if screen_data is None:
            shape[0] = screen.width()
            shape[1] = screen.height()
            shape[2] = 3
            # static assert NPY_UBYTE == pixel_t
            screen_data = np.PyArray_SimpleNew(sizeof(shape), shape, np.NPY_UBYTE)

        #cdef int * output_buffer = <int *>np.PyArray_DATA(screen_data)
        #cdef pixel_t * ale_screen_data = self.obj._getScreen().getArray()
        #for i in range(self.obj._getScreen().arraySize()):
        #    output_buffer[i] = rgb_palette[ale_screen_data[i]]

        cdef void * output_buffer = np.PyArray_DATA(screen_data)
        #self.obj.theOSystem.get().colourPalette().setPalette("z26", "NTSC")
        self.obj.theOSystem.get().colourPalette().applyPaletteRGB(<uInt8 *>output_buffer, <uInt8 *>screen.getArray(), screen.arraySize())

        return screen_data

    def getScreenGrayscale(self, screen_data=None):
        """This function fills screen_data with the data in grayscale
        screen_data MUST be a numpy array of uint8. This can be initialized like so:
        screen_data = np.empty((height,width,1), dtype=np.uint8)
        If it is None,  then this function will initialize it.
        """
        '''
        size_t w = ale->getScreen().width();
        size_t h = ale->getScreen().height();
        size_t screen_size = w*h;
        pixel_t *ale_screen_data = ale->getScreen().getArray();
        
        ale->theOSystem->colourPalette().applyPaletteGrayscale(output_buffer, ale_screen_data, screen_size);
        '''
        #cdef np.ndarray[np.NPY_UBYTE, ndim=3] screen_data
        cdef const ALEScreen * screen = &self.obj.getScreen()
        cdef np.npy_intp shape[3]
        if screen_data is None:
            shape[0] = screen.width()
            shape[1] = screen.height()
            shape[2] = 1
            screen_data = np.PyArray_SimpleNew(sizeof(shape), shape, np.NPY_UBYTE)

        cdef void * output_buffer = np.PyArray_DATA(screen_data)
        self.obj.theOSystem.get().colourPalette().applyPaletteGrayscale(<uInt8 *>output_buffer, <uInt8 *>screen.getArray(), screen.arraySize())

        return screen_data

    def getRAMSize(self):
        return self.obj.getRAM().size()

    def getRAM(self, ram=None):
        """This function grabs the atari RAM.
        ram MUST be a numpy array of uint8/int8. This can be initialized like so:
        ram = np.array(ram_size, dtype=uint8)
        Notice: It must be ram_size where ram_size can be retrieved via the getRAMSize function.
        If it is None,  then this function will initialize it.
        """
        '''
        unsigned char *ale_ram = ale->getRAM().array();
        int size = ale->getRAM().size();
        memcpy(ram,ale_ram,size*sizeof(unsigned char));
        '''
        cdef np.npy_intp shape[1]
        cdef const ALERAM * ale_ram = &self.obj.getRAM()
        if ram is None:
            shape[0] = ale_ram.size()
            return np.PyArray_SimpleNewFromData(sizeof(shape), shape, np.NPY_UBYTE, ale_ram.array())

        cdef void * raw = np.PyArray_DATA(ram)
        memcpy(raw, ale_ram.array(), ale_ram.size())

        return ram

    def saveScreenPNG(self, filename):
        return self.obj.saveScreenPNG(filename.encode('utf-8'))
        #return self.obj.saveScreenPNG(filename)

    def saveState(self):
        return self.obj.saveState()

    def loadState(self):
        return self.obj.loadState()

    def cloneState(self):
        return ALEState(self)

    def restoreState(self, ALEState state):
        return state.restore(self)
