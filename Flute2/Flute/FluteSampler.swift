//
//  FluteSampler.swift
//  Flute
//
//  Created by Denis Malykh on 15.06.17.
//  Copyright © 2017 Yandex. All rights reserved.
//

import Foundation
import Accelerate

class FluteSampler {
//    g2
//    private let Wx_rows = 1697
//    private let Wx_cols = 2000
//    
//    private let Wy_rows = 501
//    private let Wy_cols = 1196
//    
//    private let hiddenSize = 500
    
    // g4
    private let Wx_rows = 1947
    private let Wx_cols = 3000
    
    private let Wy_rows = 751
    private let Wy_cols = 1196
    
    private let hiddenSize = 750
    
    /* These two look-up tables were exported from the Python training script. */
    private let index2note = [24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 100, 102, 108]

    private let index2offset = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 156, 158, 159, 160, 162, 163, 164, 165, 168, 169, 170, 171, 172, 173, 176, 177, 178, 179, 180, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 194, 196, 197, 198, 199, 200, 201, 202, 204, 206, 207, 208, 209, 210, 211, 213, 216, 217, 218, 219, 220, 223, 225, 230, 231, 232, 233, 235, 236, 237, 238, 239, 240, 244, 249, 254, 255, 256, 259, 260, 264, 266, 268, 269, 270, 273, 274, 276, 278, 279, 283, 284, 285, 288, 290, 291, 292, 293, 295, 297, 300, 301, 302, 304, 305, 309, 310, 312, 316, 319, 320, 321, 326, 327, 328, 331, 336, 338, 344, 345, 346, 348, 355, 358, 360, 364, 366, 369, 370, 374, 375, 379, 384, 389, 393, 394, 400, 401, 405, 406, 408, 409, 418, 420, 422, 427, 428, 432, 441, 446, 450, 454, 457, 461, 465, 468, 475, 476, 479, 480, 484, 500, 504, 513, 514, 518, 523, 528, 535, 537, 547, 552, 556, 559, 572, 576, 579, 588, 590, 592, 600, 614, 619, 624, 633, 634, 638, 648, 652, 653, 660, 666, 667, 672, 681, 686, 710, 720, 739, 744, 758, 768, 772, 780, 789, 790, 796, 840, 864, 873, 900, 912, 960, 1008, 1056, 1065, 1080, 1137, 1152, 1180, 1200, 1248, 1286, 1320, 1358, 1440, 1540, 1541, 1577, 1582, 1860, 2220, 2280, 2400, 2640, 2880, 3020, 8262]
    
    private let index2duration = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239, 240, 242, 243, 244, 245, 247, 248, 249, 250, 251, 252, 254, 255, 256, 257, 258, 259, 260, 262, 263, 264, 265, 266, 267, 268, 269, 270, 271, 272, 273, 274, 276, 277, 278, 279, 280, 281, 282, 283, 284, 285, 287, 288, 290, 291, 292, 293, 294, 295, 296, 297, 298, 300, 301, 302, 303, 304, 305, 306, 307, 308, 309, 310, 311, 312, 314, 316, 317, 320, 321, 322, 324, 326, 327, 328, 329, 331, 332, 333, 334, 335, 336, 337, 338, 339, 340, 341, 342, 344, 345, 346, 347, 348, 349, 350, 351, 352, 353, 355, 356, 358, 359, 360, 361, 362, 363, 364, 365, 367, 369, 370, 372, 373, 374, 375, 377, 378, 379, 380, 382, 384, 385, 388, 389, 390, 392, 393, 394, 395, 397, 398, 400, 403, 404, 405, 406, 407, 408, 410, 411, 413, 415, 416, 418, 419, 420, 422, 423, 424, 425, 426, 427, 428, 430, 431, 432, 433, 435, 436, 437, 440, 441, 442, 443, 444, 445, 447, 449, 450, 451, 452, 454, 456, 457, 459, 460, 461, 465, 466, 468, 470, 471, 472, 475, 476, 480, 481, 482, 483, 490, 500, 504, 507, 508, 510, 511, 512, 516, 520, 524, 526, 527, 528, 529, 532, 533, 536, 538, 540, 543, 552, 554, 555, 557, 560, 562, 563, 564, 565, 566, 568, 569, 571, 574, 576, 580, 583, 584, 586, 591, 592, 593, 596, 598, 600, 601, 605, 608, 610, 612, 615, 618, 619, 620, 621, 624, 633, 634, 635, 636, 638, 640, 641, 642, 644, 648, 652, 653, 655, 656, 660, 662, 663, 664, 669, 672, 673, 674, 676, 677, 682, 684, 686, 692, 696, 698, 700, 701, 702, 707, 708, 711, 712, 713, 718, 720, 723, 732, 736, 740, 749, 768, 773, 777, 778, 780, 788, 789, 791, 800, 802, 804, 806, 807, 810, 816, 821, 825, 826, 832, 835, 840, 842, 845, 854, 855, 864, 865, 868, 869, 870, 874, 879, 880, 884, 888, 893, 897, 902, 909, 912, 916, 921, 922, 926, 931, 936, 943, 950, 960, 965, 976, 979, 1001, 1008, 1029, 1049, 1051, 1066, 1074, 1076, 1080, 1082, 1108, 1124, 1137, 1152, 1167, 1176, 1181, 1186, 1187, 1200, 1210, 1224, 1239, 1258, 1268, 1282, 1296, 1315, 1324, 1325, 1330, 1353, 1383, 1426, 1440, 1532, 1572, 1690, 1696, 1720, 1728, 1753, 1800, 1813, 1824, 1843, 1896, 1901, 1920, 2040, 2065, 2088, 2492, 2516, 2765, 2880, 3288, 3840]

    private let index2velocity = [1, 30, 31, 32, 33, 34, 35, 36, 37, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127]
    
    private let noteVectorSize: Int
    private let offsetVectorSize: Int
    private let durationVectorSize: Int
    private let velocityVectorSize: Int
    
    let Wx_data: Data
    let Wy_data: Data
    
    var c: [Float]
    var h: [Float]
    
    init() {
        let Wx_url = Bundle.main.url(forResource: "g2.Wx", withExtension: "bin")!
        Wx_data = try! Data(contentsOf: Wx_url)
        
        let Wy_url = Bundle.main.url(forResource: "g2.Wy", withExtension: "bin")!
        Wy_data = try! Data(contentsOf: Wy_url)
        
        noteVectorSize = index2note.count
        offsetVectorSize = index2offset.count
        durationVectorSize = index2duration.count
        velocityVectorSize = index2velocity.count
        
        c = [Float](repeating: 0, count: hiddenSize)
        h = [Float](repeating: 0, count: hiddenSize + 1)
    }
    
    /*
     Returns a new list of (note, ticks) pairs.
     */
    func sample(_ n: Int) -> [(Int, Int, Int, Int)] {
        var seedIndexNote = Math.random(noteVectorSize)
        var seedIndexOffset = Math.random(offsetVectorSize)
        var seedIndexDuration = Math.random(durationVectorSize)
        var seedIndexVelocity = Math.random(velocityVectorSize)
        
        // Start with a random memory.
        Math.uniformRandom(&h, hiddenSize, 0.1)
        Math.uniformRandom(&c, hiddenSize, 0.1)
        
        // Working space.
        var x = [Float](repeating: 0, count: noteVectorSize + offsetVectorSize + durationVectorSize + velocityVectorSize + hiddenSize + 1)
        var y = [Float](repeating: 0, count: noteVectorSize + offsetVectorSize + durationVectorSize + velocityVectorSize)
        var gates = [Float](repeating: 0, count: hiddenSize*4)
        var tmp = [Float](repeating: 0, count: hiddenSize)
        
        var sampled: [(Int, Int, Int, Int)] = []
        
        for _ in 0..<n {
            // One-hot encode the input values for the notes and ticks separately.
            x[seedIndexNote] = 1
            x[seedIndexOffset + noteVectorSize] = 1
            x[seedIndexDuration + noteVectorSize + offsetVectorSize] = 1
            x[seedIndexVelocity + noteVectorSize + offsetVectorSize + durationVectorSize] = 1
            
            // Copy the h vector into x.
            x.withUnsafeMutableBufferPointer { buf in
                let ptr = buf.baseAddress!.advanced(by: noteVectorSize + offsetVectorSize + durationVectorSize + velocityVectorSize)
                memcpy(ptr, &h, hiddenSize * MemoryLayout<Float>.stride)
            }
            
            // Set the last element to 1 for the bias.
            x[x.count - 1] = 1
            
            // Multiply x with Wx.
            Wx_data.withUnsafeBytes { Wx in
                Math.matmul(&x, Wx, &gates, 1, Wx_cols, Wx_rows)
            }
            
            gates.withUnsafeMutableBufferPointer { ptr in
                let gateF = ptr.baseAddress!
                let gateI = gateF.advanced(by: hiddenSize)
                let gateO = gateI.advanced(by: hiddenSize)
                let gateG = gateO.advanced(by: hiddenSize)
                
                // Compute the activations of the gates.
                Math.sigmoid(gateF, hiddenSize*3)
                Math.tanh(gateG, hiddenSize)
                
                // c[t] = sigmoid(gateF) * sigmoid(c[t-1]) + sigmoid(gateI) * tanh(gateG)
                Math.multiply(&c, gateF, &c, hiddenSize)
                Math.multiply(gateI, gateG, &tmp, hiddenSize)
                Math.add(&tmp, &c, hiddenSize)
                
                // h[t] = sigmoid(gateO) * tanh(c[t])
                Math.tanh(&c, &tmp, hiddenSize)
                Math.multiply(gateO, &tmp, &h, hiddenSize)
            }
            
            // Set the last element to 1 for the bias.
            h[h.count - 1] = 1
            
            // Multiply h with Wy to get y.
            Wy_data.withUnsafeBytes { Wy in
                Math.matmul(&h, Wy, &y, 1, Wy_cols, Wy_rows)
            }
            
            y.withUnsafeMutableBufferPointer { ptr in
                let yNote = ptr.baseAddress!
                let yOffset = yNote.advanced(by: noteVectorSize)
                let yDuration = yOffset.advanced(by: offsetVectorSize)
                let yVelocity = yDuration.advanced(by: durationVectorSize)
                
                // Predict the next note and duration.
                Math.softmax(yNote, noteVectorSize)
                Math.softmax(yOffset, offsetVectorSize)
                Math.softmax(yDuration, durationVectorSize)
                Math.softmax(yVelocity, velocityVectorSize)
                
                // Randomly sample from the output probability distributions.
                let noteIndex = Math.randomlySample(yNote, noteVectorSize)
                let offsetIndex = Math.randomlySample(yOffset, offsetVectorSize)
                let durationIndex = Math.randomlySample(yDuration, durationVectorSize)
                let velocityIndex = Math.randomlySample(yVelocity, velocityVectorSize)
                sampled.append((index2note[noteIndex], index2offset[offsetIndex], index2duration[durationIndex], index2velocity[velocityIndex]))
                
                // Use the output as the next input.
                x[seedIndexNote] = 0
                x[seedIndexOffset + noteVectorSize] = 0
                x[seedIndexDuration + noteVectorSize + offsetVectorSize] = 0
                x[seedIndexVelocity + noteVectorSize + offsetVectorSize + durationVectorSize] = 0
                seedIndexNote = noteIndex
                seedIndexOffset = offsetIndex
                seedIndexDuration = durationIndex
                seedIndexVelocity = velocityIndex
            }
        }
        
        return sampled
    }


}
