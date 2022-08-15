        LAYER_LEN:    equ 20                ; height/width of layer (square)
        SAMPLE_SIZE:  equ 100               ; sample size for training model
        TRAIN_PASSES: equ 3000              ; number of training passes to perform
        BIAS:         equ __float32__(25.0) ; bias to increase model classification accuracy

        TRAIN_SEED:   equ 0xBEEF            ; seed for training model
        VERIFY_SEED:  equ 0xDEAD            ; seed for verifying model

        DUMP_MAX:     equ 100               ; max dump files to generate (debug)
                                            ; set to 0xC0FFEE for no limit, used to create GIF (SLOW!)