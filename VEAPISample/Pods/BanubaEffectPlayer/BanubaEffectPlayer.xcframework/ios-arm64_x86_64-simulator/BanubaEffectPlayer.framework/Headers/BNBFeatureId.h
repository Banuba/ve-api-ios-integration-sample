// AUTOGENERATED FILE - DO NOT MODIFY!
// This file generated by Djinni from recognizer.djinni

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, BNBFeatureId)
{
    BNBFeatureIdFrx,
    BNBFeatureIdActionUnits,
    BNBFeatureIdBackground,
    BNBFeatureIdHair,
    BNBFeatureIdEyes,
    BNBFeatureIdSkin,
    BNBFeatureIdFace,
    BNBFeatureIdFaceSkin,
    BNBFeatureIdLips,
    BNBFeatureIdLipsShine,
    BNBFeatureIdOcclussion,
    BNBFeatureIdGlasses,
    BNBFeatureIdAcne,
    BNBFeatureIdHandSkelet,
    BNBFeatureIdFrameBrightness,
    BNBFeatureIdEyeBags,
    BNBFeatureIdFaceAcne,
    BNBFeatureIdRuler,
    BNBFeatureIdHairStrand,
    BNBFeatureIdPoseEstimation,
    /**
     * This feature will prepare blurred texture to apply on
     * input image resulting a smoothed skin. 
     */
    BNBFeatureIdSkinSmoothing,
    /** Body segmentation. I.e. bodies detection on the frame. */
    BNBFeatureIdBody,
    /** Draw NN-generated smile on user face */
    BNBFeatureIdCreepySmile,
    /** Nails segmentation and recoloring  */
    BNBFeatureIdNails,
    /** Neuro beauty preprocessing */
    BNBFeatureIdBeautyPreproc,
    /** Combined face acne and eyebags removal */
    BNBFeatureIdAcneEyebags,
    /** Combined face acne and eyebags removal, plus skin smoothing */
    BNBFeatureIdAcneEyebagsSkinSmoothing,
    BNBFeatureIdHandGestures,
};
