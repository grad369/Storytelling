//
//  UIImage-Extensions.h
//

#import <Foundation/Foundation.h>

/*
 imageAtRect() - вырезает рисунок с заданными Rect.
 imageByScalingProportionallyToMinimumSize() - масштабирование
 imageByScalingProportionallyToSize() - масштабирование
 imageByScalingToSize() - масштабирование
 imageRotatedByRadians() - повернуть изображение в радианах
 imageRotatedByDegrees() - повернуть изображение в градусах
 sizeByScalingProportionallyToSize() - размер после пропорционального пропорционального масштабирования
 rotate() - UIImageOrientationUp,            // default orientation
            UIImageOrientationDown,          // 180 deg rotation
            UIImageOrientationLeft,          // 90 deg CCW
            UIImageOrientationRight,         // 90 deg CW
            UIImageOrientationUpMirrored,    // as above but image mirrored along other axis. horizontal flip
            UIImageOrientationDownMirrored,  // horizontal flip
            UIImageOrientationLeftMirrored,  // vertical flip
            UIImageOrientationRightMirrored, // vertical flip
 rotateToPortrait() - повернуть в портретную ориентацию
 scaleSizeWithProportion() -пропорциональное масштабирование
 addText() - дабавляет текст на картинку
 imageGrayscale() - возвращает ихображение в оттенках серого
 imageSepia() - применяет фильтр сепии к изображению
 colorizeWithColor() - Заливает ихображение выбранным цветом
 imageSetShadowWithColor() - добавляет тень под картинку
 imageWith5x5GaussianBlur() - фильтр размытия по Гаусу с клеткой 5*5
 imageNegative() - конвертирует изображение в негатив
 imageWithRoundedCornerWidth() - закругляет края у изображения
 imageBlackAndWhite() - возвращает черно-белое изображение
 imageWithMask() - применяет маску к изображению
 imageWithBrightness() - устанавливает/меняет яркость у изображания
 imageWithContrast() - изменяет контрастность у изображения
 imageWithContrast:(CGFloat)contrastFactor brightness:(CGFloat)brightnessFactor - одновременно изменяет контрастьноть и яркость
 imageWithHue:(float)hue_ saturation:(float)saturation_ brightness:(float)brightness - изменение насыщенности / гаммы / яркости
 */

@interface UIImage (CS_Extensions)

-(UIImage *)imageAtRect:(CGRect)rect;
-(UIImage *)imageByScalingProportionallyToMinimumSize:(CGSize)targetSize;
-(UIImage *)imageByScalingProportionallyToSize:(CGSize)targetSize;
-(UIImage *)imageByScalingToSize:(CGSize)targetSize;
-(UIImage *)imageRotatedByRadians:(CGFloat)radians;
-(UIImage *)imageRotatedByDegrees:(CGFloat)degrees;
+(UIImage *)fastImageWithContentsOfFile:(NSString*)path;
-(CGSize) sizeByScalingProportionallyToSize:(CGSize)targetSize;
-(UIImage *)rotate:(UIImageOrientation)orient;
-(UIImage *)rotateToPortrait;
-(CGSize) scaleSizeWithProportion:(CGSize)allow;

-(UIImage *) addText:(NSString *)text font:(UIFont *)font fontColor:(UIColor *)fontColor atPoint:(CGPoint)point;

-(UIImage *) imageGrayscale;
-(UIImage *) imageSepia;
-(UIImage *) imageColorizeWithColor:(UIColor *)theColor;
-(UIImage *) imageSetShadowWithColor:(UIColor *)color shadowOffset:(CGSize)offset shadowBlur:(float)shadowBlur;
//-(UIImage *) imageBlurredUsingGuassFactor:(int)gaussFactor pixelRadius:(int)pixelRadius;
-(UIImage *) imageWith5x5GaussianBlur;
-(UIImage *) imageNegative;
-(UIImage *) imageWithRoundedCornerWidth:(int)width height:(int)height;
-(UIImage *) imageBlackAndWhite;
// The mask image cannot have ANY transparency. 
// Instead, transparent areas must be white or some value between black and white. 
// The more towards black a pixel is the less transparent it becomes.
-(UIImage *) imageWithMask:(UIImage *)maskImage;
-(UIImage *) imageWithBrightness:(float)value;
-(UIImage *) imageWithContrast:(CGFloat)contrastFactor;
-(UIImage *) imageWithContrast:(CGFloat)contrastFactor brightness:(CGFloat)brightnessFactor;
-(UIImage *) imageWithHue:(float)hue_ saturation:(float)saturation_ brightness:(float)brightness;

@end;