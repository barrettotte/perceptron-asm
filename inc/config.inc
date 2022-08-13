        LAYER_LEN:    equ 20                ; height/width of layer (square)
        SAMPLE_SIZE:  equ 75                ; sample size for training model
        TRAIN_PASSES: equ 1000              ; number of training passes to perform
        BIAS:         equ __float32__(20.0) ; bias to increase model classification accuracy
        TRAIN_SEED:   equ 0x1337            ; seed for training model
        VERIFY_SEED:  equ 0xBEEF            ; seed for verifying model