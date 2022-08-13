        LAYER_LEN:    equ 20                ; height/width of layer (square)
        SAMPLE_SIZE:  equ 10                ; sample size for training model
        TRAIN_PASSES: equ 3                 ; number of training passes to perform
        BIAS:         equ __float32__(20.0) ; bias to increase model classification accuracy
        SEED:         equ 0x1337            ; test PRNG seed