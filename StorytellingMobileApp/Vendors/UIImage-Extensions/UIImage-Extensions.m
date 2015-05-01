//
//  UIImage-Extensions.m
//

#import "UIImage-Extensions.h"

static inline double radians (double degrees) {return degrees * M_PI/180;}

CGFloat DegreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};
CGFloat RadiansToDegrees(CGFloat radians) {return radians * 180/M_PI;};

static CGRect swapWidthAndHeight(CGRect rect)
{
    CGFloat  swap = rect.size.width;
    
    rect.size.width  = rect.size.height;
    rect.size.height = swap;
    
    return rect;
}

static void addRoundedRectToPath(CGContextRef context, CGRect rect, float ovalWidth, float ovalHeight)
{
    float fw, fh;
    if (ovalWidth == 0 || ovalHeight == 0) {
        CGContextAddRect(context, rect);
        return;
    }
    CGContextSaveGState(context);
    CGContextTranslateCTM (context, CGRectGetMinX(rect), CGRectGetMinY(rect));
    CGContextScaleCTM (context, ovalWidth, ovalHeight);
    fw = CGRectGetWidth (rect) / ovalWidth;
    fh = CGRectGetHeight (rect) / ovalHeight;
    CGContextMoveToPoint(context, fw, fh/2);
    CGContextAddArcToPoint(context, fw, fh, fw/2, fh, 1);
    CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 1);
    CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 1);
    CGContextAddArcToPoint(context, fw, 0, fw, fh/2, 1);
    CGContextClosePath(context);
    CGContextRestoreGState(context);
}

@implementation UIImage (CS_Extensions)

-(UIImage *) imageAtRect:(CGRect)rect
{
	CGImageRef imageRef = CGImageCreateWithImageInRect([self CGImage], rect);
	
    UIImage* subImage = [UIImage imageWithCGImage: imageRef];
	
    CGImageRelease(imageRef);
	
	return subImage;
}

- (UIImage *)imageByScalingProportionallyToMinimumSize:(CGSize)targetSize
{
	UIImage* sourceImage = self;
	UIImage* newImage = nil;
	
	CGSize imageSize = sourceImage.size;
	CGFloat width = imageSize.width;
	CGFloat height = imageSize.height;
	
	CGFloat targetWidth = targetSize.width;
	CGFloat targetHeight = targetSize.height;
	
	CGFloat scaleFactor = 0.0;
	CGFloat scaledWidth = targetWidth;
	CGFloat scaledHeight = targetHeight;
	
	CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
	
	if (CGSizeEqualToSize(imageSize, targetSize) == NO) 
    {
		CGFloat widthFactor = targetWidth / width;
		CGFloat heightFactor = targetHeight / height;
		
		if (widthFactor > heightFactor) 
			scaleFactor = widthFactor;
		else
			scaleFactor = heightFactor;
		
		scaledWidth  = width * scaleFactor;
		scaledHeight = height * scaleFactor;
		
		// center the image
		if (widthFactor > heightFactor) 
        {
			thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5; 
		} 
        else 
        {
            if (widthFactor < heightFactor)
            {
                thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
            }
        }
	}
	
	// this is actually the interesting part:
	UIGraphicsBeginImageContext(targetSize);
	
	CGRect thumbnailRect = CGRectZero;
	thumbnailRect.origin = thumbnailPoint;
	thumbnailRect.size.width  = scaledWidth;
	thumbnailRect.size.height = scaledHeight;
	
	[sourceImage drawInRect:thumbnailRect];
	
	newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return newImage;
}


-(UIImage *) imageByScalingProportionallyToSize:(CGSize)targetSize 
{
	UIImage *sourceImage = self;
	UIImage *newImage = nil;
	
	CGSize imageSize = sourceImage.size;
	CGFloat width = imageSize.width;
	CGFloat height = imageSize.height;
	
	CGFloat targetWidth = targetSize.width;
	CGFloat targetHeight = targetSize.height;
	
	CGFloat scaleFactor = 0.0;
	CGFloat scaledWidth = targetWidth;
	CGFloat scaledHeight = targetHeight;
	
	CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
	
	if (CGSizeEqualToSize(imageSize, targetSize) == NO)
    {
		CGFloat widthFactor = targetWidth / width;
		CGFloat heightFactor = targetHeight / height;
		
		if (widthFactor < heightFactor) 
			scaleFactor = widthFactor;
		else
			scaleFactor = heightFactor;
		
		scaledWidth  = width * scaleFactor;
		scaledHeight = height * scaleFactor;
		
		if (widthFactor < heightFactor) 
        {
			thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5; 
		} 
        else 
        {
            if (widthFactor > heightFactor) 
            {
                thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
            }
		}
	}
	
	
	// this is actually the interesting part:
	UIGraphicsBeginImageContext(targetSize);
	
	CGRect thumbnailRect = CGRectZero;
	thumbnailRect.origin = thumbnailPoint;
	thumbnailRect.size.width  = scaledWidth;
	thumbnailRect.size.height = scaledHeight;
	
	[sourceImage drawInRect:thumbnailRect];
	
	newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return newImage ;
}

// seems to be safe when working in background (not on main thread) !!!
- (UIImage *)imageByScalingProportionallyToSizeAsync:(CGSize)targetSize 
{
	UIImage* sourceImage = self; 
	CGFloat targetWidth = targetSize.width;
	CGFloat targetHeight = targetSize.height;
	
	CGImageRef imageRef = [sourceImage CGImage];
	CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
	CGColorSpaceRef colorSpaceInfo = CGImageGetColorSpace(imageRef);
	
	if (bitmapInfo == kCGImageAlphaNone) 
    {
		bitmapInfo = kCGImageAlphaNoneSkipLast;
	}
	
	CGContextRef bitmap;
	if (sourceImage.imageOrientation == UIImageOrientationUp || sourceImage.imageOrientation == UIImageOrientationDown) 
    {
		bitmap = CGBitmapContextCreate(NULL, targetWidth, targetHeight, CGImageGetBitsPerComponent(imageRef), CGImageGetBytesPerRow(imageRef), colorSpaceInfo, bitmapInfo);
		
	} else 
    {
		bitmap = CGBitmapContextCreate(NULL, targetHeight, targetWidth, CGImageGetBitsPerComponent(imageRef), CGImageGetBytesPerRow(imageRef), colorSpaceInfo, bitmapInfo);
		
	}       
	
	if (sourceImage.imageOrientation == UIImageOrientationLeft) 
    {
		CGContextRotateCTM (bitmap, radians(90));
		CGContextTranslateCTM (bitmap, 0, -targetHeight);
		
	} else if (sourceImage.imageOrientation == UIImageOrientationRight) {
		CGContextRotateCTM (bitmap, radians(-90));
		CGContextTranslateCTM (bitmap, -targetWidth, 0);
		
	} else if (sourceImage.imageOrientation == UIImageOrientationUp) {
		// NOTHING
	} else if (sourceImage.imageOrientation == UIImageOrientationDown) {
		CGContextTranslateCTM (bitmap, targetWidth, targetHeight);
		CGContextRotateCTM (bitmap, radians(-180.));
	}
	
	CGContextDrawImage(bitmap, CGRectMake(0, 0, targetWidth, targetHeight), imageRef);
	CGImageRef ref = CGBitmapContextCreateImage(bitmap);
	UIImage* newImage = [UIImage imageWithCGImage:ref];
	
	CGContextRelease(bitmap);
	CGImageRelease(ref);
	
	return newImage; 
}


- (UIImage *)imageByScalingToSize:(CGSize)targetSize 
{
	UIImage *sourceImage = self;
	UIImage *newImage = nil;
	
	CGFloat targetWidth = targetSize.width;
	CGFloat targetHeight = targetSize.height;
	
	CGFloat scaledWidth = targetWidth;
	CGFloat scaledHeight = targetHeight;
	
	CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
	
	UIGraphicsBeginImageContext(targetSize);
	
	CGRect thumbnailRect = CGRectZero;
	thumbnailRect.origin = thumbnailPoint;
	thumbnailRect.size.width  = scaledWidth;
	thumbnailRect.size.height = scaledHeight;
	
	[sourceImage drawInRect:thumbnailRect];
	
	newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return newImage ;
}


-(UIImage *) imageRotatedByRadians:(CGFloat)radians
{
	return [self imageRotatedByDegrees:RadiansToDegrees(radians)];
}

-(UIImage *) imageRotatedByDegrees:(CGFloat)degrees 
{   
	// calculate the size of the rotated view's containing box for our drawing space
	UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.size.width, self.size.height)];
	CGAffineTransform t = CGAffineTransformMakeRotation(DegreesToRadians(degrees));
	rotatedViewBox.transform = t;
	CGSize rotatedSize = rotatedViewBox.frame.size;
	[rotatedViewBox release];
	
	// Create the bitmap context
	UIGraphicsBeginImageContext(rotatedSize);
	CGContextRef bitmap = UIGraphicsGetCurrentContext();
	
	// Move the origin to the middle of the image so we will rotate and scale around the center.
	CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
	
	//   // Rotate the image context
	CGContextRotateCTM(bitmap, DegreesToRadians(degrees));
	
	// Now, draw the rotated/scaled image into the context
	CGContextScaleCTM(bitmap, 1.0, -1.0);
	CGContextDrawImage(bitmap, CGRectMake(-self.size.width / 2, -self.size.height / 2, self.size.width, self.size.height), [self CGImage]);
	
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return newImage;
}

-(UIImage *) rotateToPortrait
{
	int orientation = [self imageOrientation];
	if(orientation==UIImageOrientationLeft)
		return [self rotate:UIImageOrientationLeft];
	if(orientation==UIImageOrientationRight)
		return [self rotate:UIImageOrientationRight];
	return self;	
}

-(UIImage*) rotate:(UIImageOrientation)orient
{
    CGRect             bnds = CGRectZero;
    UIImage*           copy = nil;
    CGContextRef       ctxt = nil;
    CGImageRef         imag = self.CGImage;
    CGRect             rect = CGRectZero;
    CGAffineTransform  tran = CGAffineTransformIdentity;
	
    rect.size.width  = CGImageGetWidth(imag);
    rect.size.height = CGImageGetHeight(imag);
    
    bnds = rect;
    
    switch (orient)
    {
        case UIImageOrientationUp:
			// would get you an exact copy of the original
			assert(false);
			return nil;
			
        case UIImageOrientationUpMirrored:
			tran = CGAffineTransformMakeTranslation(rect.size.width, 0.0);
			tran = CGAffineTransformScale(tran, -1.0, 1.0);
			break;
			
        case UIImageOrientationDown:
			tran = CGAffineTransformMakeTranslation(rect.size.width,
													rect.size.height);
			tran = CGAffineTransformRotate(tran, M_PI);
			break;
			
        case UIImageOrientationDownMirrored:
			tran = CGAffineTransformMakeTranslation(0.0, rect.size.height);
			tran = CGAffineTransformScale(tran, 1.0, -1.0);
			break;
			
        case UIImageOrientationLeft:
			bnds = swapWidthAndHeight(bnds);
			tran = CGAffineTransformMakeTranslation(0.0, rect.size.width);
			tran = CGAffineTransformRotate(tran, 3.0 * M_PI / 2.0);
			break;
			
        case UIImageOrientationLeftMirrored:
			bnds = swapWidthAndHeight(bnds);
			tran = CGAffineTransformMakeTranslation(rect.size.height,
													rect.size.width);
			tran = CGAffineTransformScale(tran, -1.0, 1.0);
			tran = CGAffineTransformRotate(tran, 3.0 * M_PI / 2.0);
			break;
			
        case UIImageOrientationRight:
			bnds = swapWidthAndHeight(bnds);
			tran = CGAffineTransformMakeTranslation(rect.size.height, 0.0);
			tran = CGAffineTransformRotate(tran, M_PI / 2.0);
			break;
			
        case UIImageOrientationRightMirrored:
			bnds = swapWidthAndHeight(bnds);
			tran = CGAffineTransformMakeScale(-1.0, 1.0);
			tran = CGAffineTransformRotate(tran, M_PI / 2.0);
			break;
			
        default:
			// orientation value supplied is invalid
			assert(false);
			return nil;
    }
	
    UIGraphicsBeginImageContext(bnds.size);
    ctxt = UIGraphicsGetCurrentContext();
	
    switch (orient)
    {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
			CGContextScaleCTM(ctxt, -1.0, 1.0);
			CGContextTranslateCTM(ctxt, -rect.size.height, 0.0);
			break;
			
        default:
			CGContextScaleCTM(ctxt, 1.0, -1.0);
			CGContextTranslateCTM(ctxt, 0.0, -rect.size.height);
			break;
    }
	
    CGContextConcatCTM(ctxt, tran);
    CGContextDrawImage(UIGraphicsGetCurrentContext(), rect, imag);
    
    copy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
	
    return copy;
}

+(UIImage *) fastImageWithContentsOfFile:(NSString*)path
{
	NSData *dataImage = [NSData dataWithContentsOfFile:path];
	return [UIImage imageWithData:dataImage];
}

-(CGSize) sizeByScalingProportionallyToSize:(CGSize)targetSize 
{
	UIImage *sourceImage = self;
	
	CGSize imageSize = sourceImage.size;
	CGFloat width = imageSize.width;
	CGFloat height = imageSize.height;
	
	CGFloat targetWidth = targetSize.width;
	CGFloat targetHeight = targetSize.height;
	
	CGFloat scaleFactor = 0.0;
	CGFloat scaledWidth = targetWidth;
	CGFloat scaledHeight = targetHeight;
	
	CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
	
	if (CGSizeEqualToSize(imageSize, targetSize) == NO) 
    {
		CGFloat widthFactor = targetWidth / width;
		CGFloat heightFactor = targetHeight / height;
		
		if (widthFactor < heightFactor) 
			scaleFactor = widthFactor;
		else
			scaleFactor = heightFactor;
		
		scaledWidth  = width * scaleFactor;
		scaledHeight = height * scaleFactor;
		
		// center the image
		if (widthFactor < heightFactor) {
			thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5; 
		} else if (widthFactor > heightFactor) {
			thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
		}
	}
	
	CGSize result;
	result.width = scaledWidth;
	result.height = scaledHeight;
	return result;
}

-(CGSize) scaleSizeWithProportion:(CGSize)allow
{
	CGSize real = self.size;
	CGSize result;
	
	if(real.height<allow.height || real.width<allow.width)
	{
		int x = allow.width-real.width;
		int y = allow.height-real.height;
		CGFloat mn;
		if(x<y)
			mn = (float)allow.width/(float)real.width;
		else
			mn = (float)allow.height/(float)real.height;
		result.width = real.width*mn;
		result.height = real.height*mn;
		return result;
	}
/*	if(real.height>real.width)
	{
		
		result.height = allow.height;
		result.width = real.width/(real.height/allow.height);
		
	}
	if(real.width>real.height)
	{
		result.width = allow.width;
		result.height = (allow.height*real.height)/real.width;
	}*/
	if(real.height/allow.height>=real.width/allow.width)
	{
		
		result.height = allow.height;
		result.width = real.width/(real.height/allow.height);
		
	}
	else
	{
		result.width = allow.width;
		result.height = (allow.height*real.height)/real.width;
	}
	return result;
}

//Add text to UIImage
-(UIImage *) addText:(NSString *)text font:(UIFont *)font fontColor:(UIColor *)fontColor atPoint:(CGPoint)point
{
    if ([text length] == 0)
        return self;
    
    int w = self.size.width;
    int h = self.size.height; 
    
    //lon = h - lon;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, 
                                                 w, 
                                                 h, 
                                                 8, 
                                                 4 * w, 
                                                 colorSpace, 
                                                 kCGImageAlphaPremultipliedFirst);
    
    CGContextDrawImage(context, CGRectMake(0, 0, w, h), self.CGImage);
    
    char* text1	= (char *)[text cStringUsingEncoding:NSASCIIStringEncoding];
    
    CGContextSelectFont(context, [font.fontName cStringUsingEncoding:[NSString defaultCStringEncoding]], font.pointSize, kCGEncodingMacRoman);
    CGContextSetTextDrawingMode(context, kCGTextFill);
    CGContextSetFillColorWithColor(context, fontColor.CGColor);
    
    CGContextShowTextAtPoint(context, point.x, point.y, text1, strlen(text1));
    
    CGImageRef imageMasked = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    UIImage* imageProduct = [UIImage imageWithCGImage:imageMasked];
    
    CGImageRelease(imageMasked);
    
    return imageProduct;
}

#pragma mark -
#pragma mark color
-(UIImage *) imageGrayscale
{
    UIImage* newImage = nil;
	
	if (self != nil) 
    {
        CGImageRef originalImage = [self CGImage];
        float originalWidth = CGImageGetWidth(originalImage);
        float originalHeight = CGImageGetHeight(originalImage);
        
		CGColorSpaceRef colorSapce = CGColorSpaceCreateDeviceGray();
		CGContextRef context = CGBitmapContextCreate(nil, 
                                                     originalWidth, 
                                                     originalHeight, 
                                                     8, 
                                                     originalHeight * 4, 
                                                     colorSapce, 
                                                     kCGImageAlphaNone);
		CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
		CGContextSetShouldAntialias(context, NO);
		CGContextDrawImage(context, CGRectMake(0, 0, originalWidth, originalHeight), originalImage);
		
		CGImageRef bwImage = CGBitmapContextCreateImage(context);
		CGContextRelease(context);
		CGColorSpaceRelease(colorSapce);
		
		UIImage *resultImage = [UIImage imageWithCGImage:bwImage];
		
        CGImageRelease(bwImage);

		UIGraphicsBeginImageContext(self.size);
		[resultImage drawInRect:CGRectMake(0.0, 0.0, originalWidth, originalHeight)];
		newImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
	}
	
	return newImage;
}

-(UIImage *) imageSepia
{
    CGImageRef originalImage = [self CGImage];
    float originalWidth = CGImageGetWidth(originalImage);
    float originalHeight = CGImageGetHeight(originalImage);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    void* data_ = malloc(originalHeight * originalWidth* 4);
    CGContextRef bitmapContext = CGBitmapContextCreate(data_,
                                                       originalWidth,
                                                       originalHeight,
                                                       8,
                                                       originalWidth * 4,
                                                       colorSpace,
                                                       kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(bitmapContext, CGRectMake(0, 0, CGBitmapContextGetWidth(bitmapContext), CGBitmapContextGetHeight(bitmapContext)), originalImage);
    UInt8 *data = CGBitmapContextGetData(bitmapContext);
    
    if (data == nil)
    {
        NSLog(@"Context is not a bitmap context.");
        return self;
    }
    
    int numComponents = 4;
    int bytesInContext = CGBitmapContextGetHeight(bitmapContext) * CGBitmapContextGetBytesPerRow(bitmapContext);
    
    int redIn, greenIn, blueIn, redOut, greenOut, blueOut;
	
    for (int i = 0; i < bytesInContext; i += numComponents) 
    {
        redIn = data[i];
        greenIn = data[i+1];
        blueIn = data[i+2];
		
        redOut = (int)(redIn * 0.393f) + (greenIn * 0.769f) + (blueIn * 0.189f);
        greenOut = (int)(redIn * 0.349f) + (greenIn * 0.686f) + (blueIn * 0.168f);
        blueOut = (int)(redIn * 0.272f) + (greenIn * 0.534f) + (blueIn * 0.131f);		
//        redOut = (int)(redIn * 0.3f) /*+ (greenIn * 0.59f) + (blueIn * 0.11f)*/;
//        greenOut = (int)/*(redIn * 0.3f) + */(greenIn * 0.59f) /*+ (blueIn * 0.11f)*/;
//        blueOut = (int)/*(redIn * 0.3f) + (greenIn * 0.59f) + */(blueIn * 0.11f);	        
        
        if (redOut > 255.0f) 
            redOut = 255.0f;
        if (blueOut > 255.0f) 
            blueOut = 255.0f;
        if (greenOut > 255.0f) 
            greenOut = 255.0f;
        
        data[i] = (redOut);
        data[i+1] = (greenOut);
        data[i+2] = (blueOut);
    }
    
    CGImageRef outImage = CGBitmapContextCreateImage(bitmapContext);
    UIImage* uiImage = [UIImage imageWithCGImage:outImage];
    CGImageRelease(outImage);
    free(data_);
    return uiImage;
}

-(UIImage *) imageColorizeWithColor:(UIColor *)theColor 
{
    UIGraphicsBeginImageContext(self.size);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGRect area = CGRectMake(0, 0, self.size.width, self.size.height);
    
    CGContextScaleCTM(ctx, 1, -1);
    CGContextTranslateCTM(ctx, 0, -area.size.height);
    
    CGContextSaveGState(ctx);
    CGContextClipToMask(ctx, area, self.CGImage);
    
    [theColor set];
    CGContextFillRect(ctx, area);
    
    CGContextRestoreGState(ctx);
    
    CGContextSetBlendMode(ctx, kCGBlendModeMultiply);
    
    CGContextDrawImage(ctx, area, self.CGImage);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return newImage;
}

-(UIImage *) imageSetShadowWithColor:(UIColor *)color shadowOffset:(CGSize)offset shadowBlur:(float)shadowBlur
{
    CGColorSpaceRef colourSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef shadowContext = CGBitmapContextCreate(nil, 
                                                       self.size.width + fabsf(offset.width), 
                                                       self.size.height + fabsf(offset.height), 
                                                       CGImageGetBitsPerComponent(self.CGImage), 
                                                       0, 
                                                       colourSpace, 
                                                       kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colourSpace);
    
    CGContextSetShadowWithColor(shadowContext, 
                                CGSizeMake(offset.width / 2.0f, offset.height / 2.0f), 
                                shadowBlur, 
                                color.CGColor);
    if (offset.width > 0.0f && offset.height < 0.0f)
    {
        CGContextDrawImage(shadowContext, CGRectMake(0, fabsf(offset.height), self.size.width, self.size.height), self.CGImage);
    }
    else if (offset.width > 0.0f && offset.height > 0.0f)
    {
        CGContextDrawImage(shadowContext, CGRectMake(0, fabsf(offset.width), self.size.width, self.size.height), self.CGImage);
    }
    else if (offset.width < 0.0f && offset.height < 0.0f)
    {
        CGContextDrawImage(shadowContext, CGRectMake(fabsf(offset.width), fabsf(offset.height), self.size.width, self.size.height), self.CGImage);
    }
    else if (offset.width < 0.0f && offset.height > 0.0f)
    {
        CGContextDrawImage(shadowContext, CGRectMake(fabsf(offset.height), fabsf(offset.width), self.size.width, self.size.height), self.CGImage);
    }
    
    CGImageRef shadowedCGImage = CGBitmapContextCreateImage(shadowContext);
    CGContextRelease(shadowContext);
    
    UIImage * shadowedImage = [UIImage imageWithCGImage:shadowedCGImage];
    CGImageRelease(shadowedCGImage);
    
    return shadowedImage;
}

/*CGContextRef CreateARGBBitmapContext (CGImageRef inImage)
{
    CGContextRef    context = NULL;
    CGColorSpaceRef colorSpace;
    void *          bitmapData;
    int             bitmapByteCount;
    int             bitmapBytesPerRow;
    
    size_t pixelsWide = CGImageGetWidth(inImage);
    size_t pixelsHigh = CGImageGetHeight(inImage);
    bitmapBytesPerRow   = (pixelsWide * 4);
    bitmapByteCount     = (bitmapBytesPerRow * pixelsHigh);
	
    
	colorSpace = CGColorSpaceCreateDeviceRGB();
    if (colorSpace == NULL)
        return NULL;
	
    bitmapData = malloc( bitmapByteCount );
    if (bitmapData == NULL) 
        CGColorSpaceRelease( colorSpace );
	
    context = CGBitmapContextCreate (bitmapData,
									 pixelsWide,
									 pixelsHigh,
									 8,    
									 bitmapBytesPerRow,
									 colorSpace,
									 kCGImageAlphaPremultipliedFirst );
    if (context == NULL)
        free (bitmapData);
    
    CGColorSpaceRelease( colorSpace );
	
    return context;
}


CGImageRef CreateCGImageByBlurringImage(CGImageRef inImage, NSUInteger pixelRadius, NSUInteger gaussFactor)
{
	unsigned char *srcData, *destData, *finalData;
    
    CGContextRef context = CreateARGBBitmapContext(inImage);
    if (context == NULL) 
        return NULL;
    
    size_t width = CGBitmapContextGetWidth(context);
    size_t height = CGBitmapContextGetHeight(context);
    size_t bpr = CGBitmapContextGetBytesPerRow(context);
	size_t bpp = (CGBitmapContextGetBitsPerPixel(context) / 8);
	CGRect rect = {{0,0},{width,height}}; 
	
    CGContextDrawImage(context, rect, inImage); 
	
    // Now we can get a pointer to the image data associated with the bitmap
    // context.
    srcData = (unsigned char *)CGBitmapContextGetData (context);
    if (srcData != NULL)
    {
		
		size_t dataSize = bpr * height;
		finalData = malloc(dataSize);
		destData = malloc(dataSize);
		memcpy(finalData, srcData, dataSize);
		memcpy(destData, srcData, dataSize);
        
		int sums[gaussFactor];
		int i, x, y, k;
		int gauss_sum=0;
		int radius = pixelRadius * 2 + 1;
		int *gauss_fact = malloc(radius * sizeof(int));
		
		for (i = 0; i < pixelRadius; i++)
		{
			
			gauss_fact[i] = 1 + (gaussFactor*i);
			gauss_fact[radius - (i + 1)] = 1 + (gaussFactor * i);
			gauss_sum += (gauss_fact[i] + gauss_fact[radius - (i + 1)]);
		}
		gauss_fact[(radius - 1)/2] = 1 + (gaussFactor*pixelRadius);
		gauss_sum += gauss_fact[(radius-1)/2];
		
		unsigned char *p1, *p2, *p3;
		
		for ( y = 0; y < height; y++ ) 
		{
			for ( x = 0; x < width; x++ ) 
			{
				p1 = srcData + bpp * (y * width + x); 
				p2 = destData + bpp * (y * width + x);
				
				for (i=0; i < gaussFactor; i++)
					sums[i] = 0;
				
				for(k=0;k<radius;k++)
				{
					if ((y-((radius-1)>>1)+k) < height)
						p1 = srcData + bpp * ( (y-((radius-1)>>1)+k) * width + x); 
					else
						p1 = srcData + bpp * (y * width + x);
					
					for (i = 0; i < bpp; i++)
						sums[i] += p1[i]*gauss_fact[k];
					
				}
				for (i=0; i < bpp; i++)
					p2[i] = sums[i]/gauss_sum;
			}
		}
		for ( y = 0; y < height; y++ ) 
		{
			for ( x = 0; x < width; x++ ) 
			{
				p2 = destData + bpp * (y * width + x);
				p3 = finalData + bpp * (y * width + x);
				
				
				for (i=0; i < gaussFactor; i++)
					sums[i] = 0;
				
				for(k=0;k<radius;k++)
				{
					if ((x -((radius-1)>>1)+k) < width)
						p1 = srcData + bpp * ( y * width + (x -((radius-1)>>1)+k)); 
					else
						p1 = srcData + bpp * (y * width + x);
					
					for (i = 0; i < bpp; i++)
						sums[i] += p2[i]*gauss_fact[k];
					
				}
				for (i=0; i < bpp; i++)
				{
                    p3[i] = sums[i]/gauss_sum;
				}
			}
		}
    }
	
	size_t bitmapByteCount = bpr * height;
	
	CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, destData, bitmapByteCount, NULL);
	
    CGImageRef cgImage = CGImageCreate(width, height, CGBitmapContextGetBitsPerComponent(context),
									   CGBitmapContextGetBitsPerPixel(context), CGBitmapContextGetBytesPerRow(context), CGBitmapContextGetColorSpace(context), CGBitmapContextGetBitmapInfo(context), 
									   dataProvider, NULL, true, kCGRenderingIntentDefault);
	
    CGDataProviderRelease(dataProvider);
    CGContextRelease(context); 
	if (destData)
		free(destData);
    if (finalData)
        free(finalData);
	
	return cgImage;
}

-(UIImage *) imageBlurredUsingGuassFactor:(int)gaussFactor pixelRadius:(int)pixelRadius
{
	CGImageRef retCGImage = CreateCGImageByBlurringImage(self.CGImage, pixelRadius, gaussFactor);
	UIImage* retUIImage = [UIImage imageWithCGImage:retCGImage];
	CGImageRelease(retCGImage);
	return retUIImage;	
}*/

- (UIImage*) imageWith5x5GaussianBlur 
{
    const CGFloat filter[5][5] = { 
        {1.0f/256.0f, 4.0f/256.0f, 6.0f/256.0f, 4.0f/256.0f, 1.0f/256.f},
        {4.0f/256.0f, 16.0f/256.0f, 24.0f/256.0f, 16.0f/256.0f, 4.0f/256.f},
        {6.0f/256.0f, 24.0f/256.0f, 36.0f/256.0f, 24.0f/256.0f, 6.0f/256.f},
        {4.0f/256.0f, 16.0f/256.0f, 24.0f/256.0f, 16.0f/256.0f, 4.0f/256.f},
        {1.0f/256.0f, 4.0f/256.0f, 6.0f/256.0f, 4.0f/256.0f, 1.0f/256.f}
    };
    
    CGImageRef imgRef = [self CGImage];
    
    size_t width = CGImageGetWidth(imgRef);
    size_t height = CGImageGetHeight(imgRef);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    size_t bitsPerComponent = 8;
    size_t bytesPerPixel = 4;
    size_t bytesPerRow = bytesPerPixel * width;
    size_t totalBytes = bytesPerRow * height;
    
    //Allocate Image space
    uint8_t* rawData = malloc(totalBytes);
    
    //Create Bitmap of same size
    CGContextRef context = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    //Draw our image to the context
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imgRef);
    
    for ( int y = 0; y < height; y++ ) {
        
        for ( int x = 0; x < width; x++ ) {
            
            uint8_t* pixel = rawData + (bytesPerRow * y) + (x * bytesPerPixel);
            
            CGFloat sumRed = 0;
            CGFloat sumGreen = 0;
            CGFloat sumBlue = 0;
            
            for ( int j = 0; j < 5; j++ ) 
            {
                for ( int i = 0; i < 5; i++ ) 
                {
                    if ( (y + j - 2) >= height || (y + j - 2) < 0 ) 
                    {
                        //Use zero values at edge of image
                        continue;
                    }
                    
                    if ( (x + i - 2) >= width || (x + i - 2) < 0 ) 
                    {
                        //Use Zero values at edge of image
                        continue;
                    }
                    
                    uint8_t* kernelPixel = rawData + (bytesPerRow * (y + j - 2)) + ((x + i - 2) * bytesPerPixel);
                    
                    sumRed += kernelPixel[0] * filter[j][i];
                    sumGreen += kernelPixel[1] * filter[j][i];
                    sumBlue += kernelPixel[2] * filter[j][i];
                }
            }
            
            pixel[0] = roundf(sumRed);
            pixel[1] = roundf(sumGreen);
            pixel[2] = roundf(sumBlue);
        }
    }
    
    CGImageRef newImg = CGBitmapContextCreateImage(context);
    
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    free(rawData);
    
    UIImage* image = [UIImage imageWithCGImage:newImg];
    
    CGImageRelease(newImg);
    
    return image;
}

-(UIImage *) imageNegative
{
    UIGraphicsBeginImageContext(self.size);
    CGContextSetBlendMode(UIGraphicsGetCurrentContext(), kCGBlendModeCopy);
    [self drawInRect:CGRectMake(0, 0, self.size.width, self.size.height)];
    CGContextSetBlendMode(UIGraphicsGetCurrentContext(), kCGBlendModeDifference);
    CGContextSetFillColorWithColor(UIGraphicsGetCurrentContext(),[UIColor whiteColor].CGColor);
    CGContextFillRect(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, self.size.width, self.size.height));
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return newImage;
}

-(UIImage *) imageWithRoundedCornerWidth:(int)width height:(int)height
{
    UIImage* newImage = nil;
    
	if(self != nil)
	{
		NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
		int w = self.size.width;
		int h = self.size.height;
        
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		CGContextRef context = CGBitmapContextCreate(NULL, w, h, 8, 4 * w, colorSpace, kCGImageAlphaPremultipliedFirst);
        
		CGContextBeginPath(context);
		CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
		addRoundedRectToPath(context, rect, width, height);
		CGContextClosePath(context);
		CGContextClip(context);
        
		CGContextDrawImage(context, CGRectMake(0, 0, w, h), self.CGImage);
        
		CGImageRef imageMasked = CGBitmapContextCreateImage(context);
		CGContextRelease(context);
		CGColorSpaceRelease(colorSpace);
        
		newImage = [[UIImage imageWithCGImage:imageMasked] retain];
		CGImageRelease(imageMasked);
        
		[pool release];
	}
    
    return newImage;
}

-(UIImage *) imageWithMask:(UIImage *)maskImage 
{
	CGImageRef maskRef = maskImage.CGImage; 
    
	CGImageRef mask = CGImageMaskCreate(CGImageGetWidth(maskRef),
                                        CGImageGetHeight(maskRef),
                                        CGImageGetBitsPerComponent(maskRef),
                                        CGImageGetBitsPerPixel(maskRef),
                                        CGImageGetBytesPerRow(maskRef),
                                        CGImageGetDataProvider(maskRef), NULL, false);
    
	CGImageRef masked = CGImageCreateWithMask([self CGImage], mask);
	return [UIImage imageWithCGImage:masked];
}

-(UIImage *) imageBlackAndWhite
{
    CGImageRef originalImage = [self CGImage];
    float originalWidth = CGImageGetWidth(originalImage);
    float originalHeight = CGImageGetHeight(originalImage);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    void* data_ = malloc(originalHeight * originalWidth* 4);
    CGContextRef bitmapContext = CGBitmapContextCreate(data_,
                                                       originalWidth,
                                                       originalHeight,
                                                       8,
                                                       originalWidth * 4,
                                                       colorSpace,
                                                       kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(bitmapContext, CGRectMake(0, 0, CGBitmapContextGetWidth(bitmapContext), CGBitmapContextGetHeight(bitmapContext)), originalImage);
    UInt8 *data = CGBitmapContextGetData(bitmapContext);
    int numComponents = 4;
    int bytesInContext = CGBitmapContextGetHeight(bitmapContext) * CGBitmapContextGetBytesPerRow(bitmapContext);
	
    for (int i = 0; i < bytesInContext; i += numComponents)
    {
		if ((data[i + 0] + data[i + 1] + data[i + 2]) < (255 * 3 / 2)) 
        {
            data[i + 1] = 0;
            data[i + 2] = 0;
            data[i + 0] = 0;
        } 
        else
        {
            data[i + 1] = 255;
            data[i + 2] = 255;
            data[i + 0] = 255;
        }
    }
    
    CGImageRef outImage = CGBitmapContextCreateImage(bitmapContext);
    UIImage* uiImage = [UIImage imageWithCGImage:outImage];
    CGImageRelease(outImage);
    free(data_);
    return uiImage;
}

-(UIImage *) imageWithBrightness:(float)value
{
    if ( value == 0 ) {
        return self;
    }
    
    CGImageRef imgRef = [self CGImage];
    
    size_t width = CGImageGetWidth(imgRef);
    size_t height = CGImageGetHeight(imgRef);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    size_t bitsPerComponent = 8;
    size_t bytesPerPixel = 4;
    size_t bytesPerRow = bytesPerPixel * width;
    size_t totalBytes = bytesPerRow * height;
    
    //Allocate Image space
    uint8_t* rawData = malloc(totalBytes);
    
    //Create Bitmap of same size
    CGContextRef context = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    //Draw our image to the context
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imgRef);
    
    //Perform Brightness Manipulation
    for ( int i = 0; i < totalBytes; i += 4 ) {
        
        uint8_t* red = rawData + i; 
        uint8_t* green = rawData + (i + 1); 
        uint8_t* blue = rawData + (i + 2); 
        
        *red = MIN(255,MAX(0,roundf(*red + (*red * value))));
        *green = MIN(255,MAX(0,roundf(*green + (*green * value))));
        *blue = MIN(255,MAX(0,roundf(*blue + (*blue * value))));
        
    }
    
    //Create Image
    CGImageRef newImg = CGBitmapContextCreateImage(context);
    
    //Release Created Data Structs
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    free(rawData);
    
    //Create UIImage struct around image
    UIImage* image = [UIImage imageWithCGImage:newImg];
    
    //Release our hold on the image
    CGImageRelease(newImg);
    
    //return new image!
    return image;
}

- (UIImage*) imageWithContrast:(CGFloat)contrastFactor
{
    if ( contrastFactor == 1 ) 
    {
        return self;
    }
    
    CGImageRef imgRef = [self CGImage];
    
    size_t width = CGImageGetWidth(imgRef);
    size_t height = CGImageGetHeight(imgRef);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    size_t bitsPerComponent = 8;
    size_t bytesPerPixel = 4;
    size_t bytesPerRow = bytesPerPixel * width;
    size_t totalBytes = bytesPerRow * height;
    
    uint8_t* rawData = malloc(totalBytes);
    
    CGContextRef context = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imgRef);
    
    for ( int i = 0; i < totalBytes; i += 4 ) 
    {
        
        uint8_t* red = rawData + i; 
        uint8_t* green = rawData + (i + 1); 
        uint8_t* blue = rawData + (i + 2); 
        
        *red = MIN(255,MAX(0, roundf(contrastFactor*(*red - 127.5f)) + 128));
        *green = MIN(255,MAX(0, roundf(contrastFactor*(*green - 127.5f)) + 128));
        *blue = MIN(255,MAX(0, roundf(contrastFactor*(*blue - 127.5f)) + 128));
    }
    
    CGImageRef newImg = CGBitmapContextCreateImage(context);
    
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    free(rawData);
    
    UIImage* image = [UIImage imageWithCGImage:newImg];
    
    CGImageRelease(newImg);
    return image;
}

- (UIImage*) imageWithContrast:(CGFloat)contrastFactor brightness:(CGFloat)brightnessFactor 
{
    if ( contrastFactor == 1 && brightnessFactor == 0 ) 
    {
        return self;
    }
    
    CGImageRef imgRef = [self CGImage];
    
    size_t width = CGImageGetWidth(imgRef);
    size_t height = CGImageGetHeight(imgRef);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    size_t bitsPerComponent = 8;
    size_t bytesPerPixel = 4;
    size_t bytesPerRow = bytesPerPixel * width;
    size_t totalBytes = bytesPerRow * height;
    
    uint8_t* rawData = malloc(totalBytes);
    
    CGContextRef context = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imgRef);
    
    for ( int i = 0; i < totalBytes; i += 4 ) 
    {
        uint8_t* red = rawData + i; 
        uint8_t* green = rawData + (i + 1); 
        uint8_t* blue = rawData + (i + 2); 
        
        *red = MIN(255,MAX(0,roundf(*red + (*red * brightnessFactor))));
        *green = MIN(255,MAX(0,roundf(*green + (*green * brightnessFactor))));
        *blue = MIN(255,MAX(0,roundf(*blue + (*blue * brightnessFactor))));
        
        *red = MIN(255,MAX(0, roundf(contrastFactor*(*red - 127.5f)) + 128));
        *green = MIN(255,MAX(0, roundf(contrastFactor*(*green - 127.5f)) + 128));
        *blue = MIN(255,MAX(0, roundf(contrastFactor*(*blue - 127.5f)) + 128));
    }
    
    CGImageRef newImg = CGBitmapContextCreateImage(context);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    free(rawData);
    
    UIImage* image = [UIImage imageWithCGImage:newImg];
    CGImageRelease(newImg);
    
    return image;
}

+(CGFloat) clamp:(CGFloat)pixel
{
    if(pixel > 255) return 255;
    else if(pixel < 0) return 0;
    return pixel;
}

#pragma mark -
double minRGB(double r, double g, double b){
    if (r < g){
        if (r < b){
            return r;
        }else {
            return b;
        }
    }else {
        if (g < b){
            return g;
        }else{
            return b;
        }
    }
}

double maxRGB(double r, double g, double b){
    if (r > g){
        if (r > b){
            return r;
        }else {
            return b;
        }
    }else {
        if (g > b){
            return g;
        }else {
            return b;
        }
    }
}

void rgbToHsv(double redIn,double greenIn,double blueIn,double *hue,double *saturation,double* value){
    double min,max,delta;
    
    min                         =   minRGB(redIn,greenIn,blueIn);
    max                         =   maxRGB(redIn,greenIn,blueIn);
    *value                      =   max;
    delta                       =   max - min;
    if (max != 0) {
        *saturation             =   delta/max;
    }else {
        *saturation             =   0;
        *hue                        =   -1.0;
        return ;
    }
    if (redIn == max) {
        *hue                    =   (greenIn - blueIn)/delta;
    }else if (greenIn == max) {
        *hue                    =   2 + (blueIn - redIn)/delta;
    }else {
        *hue                    =   4 + (redIn - greenIn)/delta;
    }
    *hue                        *=  60.0;
    if (*hue < 0) {
        *hue                    +=  360.0;
    }
}

void hsvToRgb(double h,double s, double v, double *r,double *g, double *b){
    int i;
    float f, p, q, t;
    if( s == 0 ) {
        // achromatic (grey)
        *r = *g = *b = v;
        return;
    }
    h                           /=  60;         // sector 0 to 5
    i                           =   floor( h );
    f                           =   h - i;          // factorial part of h
    p                           =   v * ( 1 - s );
    q                           =   v * ( 1 - s * f );
    t                           =   v * ( 1 - s * ( 1 - f ) );
    switch( i ) {
        case 0:
            *r = v;
            *g = t;
            *b = p;
            break;
        case 1:
            *r = q;
            *g = v;
            *b = p;
            break;
        case 2:
            *r = p;
            *g = v;
            *b = t;
            break;
        case 3:
            *r = p;
            *g = q;
            *b = v;
            break;
        case 4:
            *r = t;
            *g = p;
            *b = v;
            break;
        default:        // case 5:
            *r = v;
            *g = p;
            *b = q;
            break;
    }
}

-(UIImage *) imageWithHue:(float)hue_ saturation:(float)saturation_ brightness:(float)brightness
{
    CGImageRef originalImage = [self CGImage];
    float originalWidth = CGImageGetWidth(originalImage);
    float originalHeight = CGImageGetHeight(originalImage);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    void* data_ = malloc(originalHeight * originalWidth * 4);
    CGContextRef bitmapContext = CGBitmapContextCreate(data_,
                                                       originalWidth,
                                                       originalHeight,
                                                       8,
                                                       originalWidth * 4,
                                                       colorSpace,
                                                       kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(bitmapContext, CGRectMake(0, 0, CGBitmapContextGetWidth(bitmapContext), CGBitmapContextGetHeight(bitmapContext)), originalImage);
    UInt8 *data = CGBitmapContextGetData(bitmapContext);
    int numComponents = 4;
    int bytesInContext = CGBitmapContextGetHeight(bitmapContext) * CGBitmapContextGetBytesPerRow(bitmapContext);
    double redIn, greenIn, blueIn,alphaIn;
    double hue,saturation,value;
    
    for (int i = 0; i < bytesInContext; i += numComponents)
    {
        redIn = (double)data[i]/255.0;
        greenIn = (double)data[i+1]/255.0;
        blueIn = (double)data[i+2]/255.0;
        alphaIn = (double)data[i+3]/255.0;
        
        rgbToHsv(redIn,greenIn,blueIn,&hue,&saturation,&value);
        
        hue = hue * hue_;
        if (hue > 360) 
        {
            hue = 360;
        }
        
        saturation = saturation * saturation_;
        if (saturation > 1.0) 
        {
            saturation = 1.0;
        }
        
        value = value * brightness;
        if (value > 1.0) 
        {
            value = 1.0;
        }
        
        hsvToRgb(hue,saturation,value,&redIn,&greenIn,&blueIn);
        data[i] = redIn * 255.0;
        data[i+1] = greenIn * 255.0;
        data[i+2] = blueIn * 255.0;
    }
    
    CGImageRef outImage = CGBitmapContextCreateImage(bitmapContext);
    UIImage* myImage = [UIImage imageWithCGImage:outImage];
    CGImageRelease(outImage);
    free(data_);
    
    return myImage;
}

@end;