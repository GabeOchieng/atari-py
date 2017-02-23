from libcpp.string cimport string
from libcpp.vector cimport vector
from libcpp cimport bool, vector


ctypedef unsigned char uInt8


cdef extern from "<memory>" namespace "std":
    cdef cppclass auto_ptr[T]:
        auto_ptr(T* ptr)

        # Observers
        T* get() const
        T& operator*()
        #T* operator->() # Not Supported
        bool operator bool()
        bool operator!()

cdef extern from "common/ColourPalette.hpp" nogil:
    cdef cppclass ColourPalette:
        ColourPalette()

        # Converts a given palette value in range [0, 255] into its RGB components
        void getRGB(int val, int &r, int &g, int &b) const

        # Converts a given palette value into packed RGB (format 0x00RRGGBB)
        #uInt32 getRGB(int val) const;

        # Returns the byte-sized grayscale value for this palette index
        uInt8 getGrayscale(int val) const

        # Applies the current RGB palette to the src_buffer and returns the results in dst_buffer
        # For each byte in src_buffer, three bytes are returned in dst_buffer
        # 8 bits => 24 bits
        void applyPaletteRGB(uInt8 * dst_buffer, uInt8 * src_buffer, size_t src_size)

        # Applies the current grayscale palette to the src_buffer and returns the results in dst_buffer
        # For each byte in src_buffer, a single byte is returned in dst_buffer
        # 8 bits => 8 bits
        void applyPaletteGrayscale(uInt8 * dst_buffer, uInt8 * src_buffer, size_t src_size)

        # Loads all defined palettes with PAL color-loss data depending
        # on 'state'.
        # Sets the palette according to the given palette name.
        #        # @param type  The palette type = {standard, z26, user}
        # @param displayFormat The display format = { NTSC, PAL, SECAM }
        void setPalette(const string& type,
                        const string& displayFormat)

        #
        # Loads a user-defined palette file (from OSystem::paletteFile), filling the
        # appropriate user-defined palette arrays.
        #
        void loadUserPalette(const string& paletteFile)


cdef extern from "emucore/OSystem.hxx" nogil:
    cdef cppclass OSystem:
        ColourPalette & colourPalette()


cdef extern from "environment/ale_screen.hpp" nogil:
    ctypedef unsigned char pixel_t

    # A simple wrapper around an Atari screen
    cdef cppclass ALEScreen:
        ALEScreen(int h, int w) except +
        ALEScreen(const ALEScreen &rhs) except +
        
        ALEScreen& operator=(const ALEScreen &rhs)
        
        # pixel accessors, (row, column)-ordered
        pixel_t get(int r, int c) const
        pixel_t * pixel(int r, int c)
        
        # Access a whole row
        pixel_t * getRow(int r) const
        
        # Access the whole array
        pixel_t * getArray() const
        
        # Dimensionality information
        size_t height() const
        size_t width() const
        
        # Returns the size of the underlying array
        size_t arraySize() const
        
        # Returns whether two screens are equal
        bool equals(const ALEScreen &rhs) const


cdef extern from "environment/ale_screen.hpp" nogil:
    ctypedef unsigned char byte_t
    #define RAM_SIZE (128)

    # A simple wrapper around the Atari RAM 
    cdef cppclass ALERAM:
        ALERAM() except +
        ALERAM(const ALERAM &rhs) except +
    
        ALERAM& operator=(const ALERAM &rhs)
    
        # Byte accessors
        byte_t get(unsigned int x) const
        byte_t * byte(unsigned int x)
       
        # Returns the whole array (equivalent to byte(0))
        byte_t * array() const
    
        size_t size() const
        # Returns whether two copies of the RAM are equal
        bool equals(const ALERAM &rhs) const




cdef extern from "common/Constants.h" nogil:
    # Define actions
    ctypedef enum Action:
        PLAYER_A_NOOP           = 0,
        PLAYER_A_FIRE           = 1,
        PLAYER_A_UP             = 2,
        PLAYER_A_RIGHT          = 3,
        PLAYER_A_LEFT           = 4,
        PLAYER_A_DOWN           = 5,
        PLAYER_A_UPRIGHT        = 6,
        PLAYER_A_UPLEFT         = 7,
        PLAYER_A_DOWNRIGHT      = 8,
        PLAYER_A_DOWNLEFT       = 9,
        PLAYER_A_UPFIRE         = 10,
        PLAYER_A_RIGHTFIRE      = 11,
        PLAYER_A_LEFTFIRE       = 12,
        PLAYER_A_DOWNFIRE       = 13,
        PLAYER_A_UPRIGHTFIRE    = 14,
        PLAYER_A_UPLEFTFIRE     = 15,
        PLAYER_A_DOWNRIGHTFIRE  = 16,
        PLAYER_A_DOWNLEFTFIRE   = 17,
        PLAYER_B_NOOP           = 18,
        PLAYER_B_FIRE           = 19,
        PLAYER_B_UP             = 20,
        PLAYER_B_RIGHT          = 21,
        PLAYER_B_LEFT           = 22,
        PLAYER_B_DOWN           = 23,
        PLAYER_B_UPRIGHT        = 24,
        PLAYER_B_UPLEFT         = 25,
        PLAYER_B_DOWNRIGHT      = 26,
        PLAYER_B_DOWNLEFT       = 27,
        PLAYER_B_UPFIRE         = 28,
        PLAYER_B_RIGHTFIRE      = 29,
        PLAYER_B_LEFTFIRE       = 30,
        PLAYER_B_DOWNFIRE       = 31,
        PLAYER_B_UPRIGHTFIRE    = 32,
        PLAYER_B_UPLEFTFIRE     = 33,
        PLAYER_B_DOWNRIGHTFIRE  = 34,
        PLAYER_B_DOWNLEFTFIRE   = 35,
        RESET                   = 40, # MGB: Use SYSTEM_RESET to reset the environment.
        UNDEFINED               = 41,
        RANDOM                  = 42,
        SAVE_STATE              = 43,
        LOAD_STATE              = 44,
        SYSTEM_RESET            = 45,
        LAST_ACTION_INDEX       = 50

    #define PLAYER_A_MAX (18)
    #define PLAYER_B_MAX (36)

    string action_to_string(Action a)

    # Define datatypes
    ctypedef vector[Action] ActionVect

    # reward type for RL interface
    ctypedef int reward_t

    # Other constant values
    #define RAM_LENGTH 128

cdef extern from "ale_interface.hpp" nogil:
    #define PADDLE_DELTA 23000
    # MGB Values taken from Paddles.cxx (Stella 3.3) - 1400000 * [5,235] / 255
    #define PADDLE_MIN 27450
    # MGB - was 1290196; updated to 790196... seems to be fine for breakout and pong; 
    #  avoids pong paddle going off screen
    #define PADDLE_MAX 790196 
    #define PADDLE_DEFAULT_VALUE (((PADDLE_MAX - PADDLE_MIN) / 2) + PADDLE_MIN)
    
    cdef cppclass ALEState:
        ALEState() except +
        # Copy constructor
        ALEState(const ALEState &rhs) except +
        # Makes a copy of this state, also storing emulator information provided as a string
        ALEState(const ALEState &rhs, string serialized) except +
    
        # Resets the system to its start state. numResetSteps 'RESET' actions are taken after the start
        void reset(int numResetSteps = 1)
    
        # Returns true if the two states contain the same saved information
        bool equals(ALEState &state)
    
        #notused#void resetPaddles(Event *)
    
        # Applies paddle actions. This actually modifies the game state by updating the paddle resistances
        #notused#void applyActionPaddles(Event * event_obj, int player_a_action, int player_b_action)
        # Sets the joystick events. No effect until the emulator is run forward
        #notused#void setActionJoysticks(Event * event_obj, int player_a_action, int player_b_action)
    
        void incrementFrame(int steps = 1)
        
        void resetEpisodeFrameNumber()
        
        # Get the frames executed so far
        const int getFrameNumber() const
    
        # Get the number of frames executed this episode
        const int getEpisodeFrameNumber() const


cdef extern from "ale_interface.hpp" nogil:
    cdef cppclass ALEInterface:
        ALEInterface() except +
        #notused#~ALEInterface()
        # Legacy constructor
        ALEInterface(bool display_screen) except +
      
        # Get the value of a setting.
        string getString(const string& key)
        int getInt(const string& key)
        bool getBool(const string& key)
        float getFloat(const string& key)
      
        # Set the value of a setting. loadRom() must be called before the
        # setting will take effect.
        void setString(const string& key, const string& value)
        void setInt(const string& key, const int value)
        void setBool(const string& key, const bool value)
        void setFloat(const string& key, const float value)
      
        # Resets the Atari and loads a game. After this call the game
        # should be ready to play. This is necessary after changing a
        # setting for the setting to take effect.
        void loadROM(string rom_file)
      
        # Applies an action to the game and returns the reward. It is the
        # user's responsibility to check if the game has ended and reset
        # when necessary - this method will keep pressing buttons on the
        # game over screen.
        reward_t act(Action action)
      
        # Indicates if the game has ended.
        bool game_over()
      
        # Resets the game, but not the full system.
        void reset_game()
      
        # Returns the vector of legal actions. This should be called only
        # after the rom is loaded.
        ActionVect getLegalActionSet()
      
        # Returns the vector of the minimal set of actions needed to play
        # the game.
        ActionVect getMinimalActionSet()
      
        # Returns the frame number since the loading of the ROM
        int getFrameNumber()
      
        # The remaining number of lives.
        const int lives()
      
        # Returns the frame number since the start of the current episode
        int getEpisodeFrameNumber()
      
        # Returns the current game screen
        const ALEScreen &getScreen()
      
        # Returns the current RAM content
        const ALERAM &getRAM()
      
        # Saves the state of the system
        void saveState()
      
        # Loads the state of the system
        void loadState()
      
        ALEState cloneState()
      
        void restoreState(const ALEState& state)
      
        # Save the current screen as a png file
        void saveScreenPNG(const string& filename)
      
        # Creates a ScreenExporter object which can be used to save a sequence of frames. Ownership 
        # said object is passed to the caller. Frames are saved in the directory 'path', which needs
        # to exists. 
        #notused#ScreenExporter * createScreenExporter(const string &path) const
      
        auto_ptr[OSystem] theOSystem
        #notused#auto_ptr[Settings] theSettings
        #notused#auto_ptr[RomSettings] romSettings
        #notused#auto_ptr[StellaEnvironment] environment
        int max_num_frames # Maximum number of frames for each episode
      
        # Display ALE welcome message
        @staticmethod
        string welcomeMessage()
        @staticmethod
        void disableBufferedIO()
        #notused#@staticmethod
        #notused#void createOSystem(std::auto_ptr[OSystem] &theOSystem,
        #notused#                   std::auto_ptr[Settings] &theSettings)
        #notused#@staticmethod
        #notused#void loadSettings(const string& romfile,
        #notused#                  std::auto_ptr[OSystem] &theOSystem)
