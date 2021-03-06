//
//  QMPlayerController.m
//  QQMusic
//
//  Created by AenyMo on 16/4/12.
//  Copyright © 2016年 AenyMo. All rights reserved.
//

#import "QMPlayerController.h"
#import "QMMusicPlayer.h"
#import "UIView+Extension.h"
#import "NSString+Extension.h"

#import "QMTopDisplayView.h"

#import "QMMusics.h"

#import <AVFoundation/AVFoundation.h>

@interface QMPlayerController ()

@property (weak, nonatomic) IBOutlet UIImageView *backgroundImage;


@property (weak, nonatomic) IBOutlet UILabel *currentTime;
@property (weak, nonatomic) IBOutlet UIImageView *sliderRight;
@property (weak, nonatomic) IBOutlet UIImageView *sliderLeft;
@property (weak, nonatomic) IBOutlet UIImageView *sliderThumb;
@property (weak, nonatomic) IBOutlet UILabel *totalTime;

@property (weak, nonatomic) IBOutlet UIButton *playButton;

@property (weak, nonatomic) IBOutlet QMTopDisplayView *topView;

/** 记录手势开始的位置 */
@property (nonatomic, assign) CGPoint startPoint;
/** 记录当前位置 */
@property (nonatomic, assign) CGPoint currentPoint;

/** 播放器 */
@property (nonatomic, strong) QMMusicPlayer *player;


@end

@implementation QMPlayerController

/** 创建播放器单例 */
- (QMMusicPlayer *)player {
    
    if (_player == nil) {
        //
        _player = [QMMusicPlayer shareMusicPlayer];
        
        
        //添加观察者
        [_player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    }
    
    return _player;
}


/** 初始化 */
- (instancetype)init {
    
    if (self = [super init]) {
        //
        //获取主窗口
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        
        //设置View的大小等于主窗口的大小
        self.view.frame = window.bounds;
        
        //设置默认隐藏View
        self.view.transform = CGAffineTransformMakeTranslation(0, self.view.bounds.size.height);
        
        //添加到主窗口上
        [window addSubview:self.view];
        
        //初始化数据
        QMMusics *music = self.player.musics[self.player.playingIndex];
        
        //设置歌词
        self.topView.lyric = music.lrcname;
        
        //设置歌曲信息
        self.topView.title = music.name;
        self.topView.singer = music.singer;
        self.topView.singerIcon = music.singerIcon;
        
        //设置背景
        self.backgroundImage.image = [UIImage imageNamed:music.singerIcon];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //开始动画
    [self.topView startRotation];
    
    //监听定时器 通知
    [[NSNotificationCenter defaultCenter] addObserverForName:@"playerTimerUpdate" object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        //
        [self updateProgress];
        
    }];
    
    //监听 切换音乐 通知
    [[NSNotificationCenter defaultCenter] addObserverForName:@"QMMusicPlayerPlayingChanged" object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        //
//        NSLog(@"%@", note);
        QMMusics *music = note.userInfo[@"playingModel"];
        
        //设置歌词
        self.topView.lyric = music.lrcname;
        
        //设置歌曲信息
        self.topView.title = music.name;
        self.topView.singer = music.singer;
        self.topView.singerIcon = music.singerIcon;
        
        //设置背景
        self.backgroundImage.image = [UIImage imageNamed:music.singerIcon];
        
        [self.topView startRotation];
        
    }];
}


#pragma mark - 手势播放控制
/** 点击手势 */
- (IBAction)tapPlay:(UITapGestureRecognizer *)sender {
    
    //获取当前点
    CGPoint point = [sender locationInView:self.sliderRight];
    
    //刷新进度条
    NSTimeInterval time = (point.x / self.sliderRight.width) * self.player.totalTime;
    
    //快进歌曲     重新设置当前时间
    self.player.currentTime = time;
    
    [self updateProgress];
}

/** 拖拽手势 */
- (IBAction)panPlay:(UIPanGestureRecognizer *)sender {
    
    CGPoint point = [sender locationInView:self.sliderRight];
    
    if (point.x > self.sliderRight.width) {
        //
        point.x = self.sliderRight.width - 1;
        
    } else if (point.x < 0) {
        
        point.x = 0;
    }
    
    NSTimeInterval time = (point.x / self.sliderRight.width) * self.player.totalTime;
    
    //快进歌曲     重新设置当前时间
    self.player.currentTime = time;
    
    [self updateProgress];
}

/** 关闭播放界面 */
- (IBAction)panClose:(UIPanGestureRecognizer *)sender {
    
    if (sender.state == UIGestureRecognizerStateBegan) {    //手势开始
        //获取起点
        self.startPoint = [sender locationInView:self.view];
        
    } else if (sender.state == UIGestureRecognizerStateChanged) {   //手势过程中
        //获取当前点 (相对于主窗口的位置)
        self.currentPoint = [sender locationInView:self.view.window];
        
        //移动界面
        self.view.transform = CGAffineTransformMakeTranslation(0, self.currentPoint.y - self.startPoint.y);
        
    } else if (sender.state == UIGestureRecognizerStateEnded) {     //手势结束
        
        
        if (self.currentPoint.y > self.view.height * 0.3) {
            //
            [self back];
        } else {
            
            [UIView animateWithDuration:0.3 animations:^{
                self.view.transform = CGAffineTransformMakeTranslation(0, 0);
            }];
        }
    }
    
}


#pragma mark - 播放控制
/** 播放/暂停 */
- (IBAction)play {
    
    if ([self.player pause]) {  //暂停
        
    } else if ([self.player play]) {    //播放
        
    }
}

/** 下一曲 */
- (IBAction)next {
    
    [self.player nextOne];
}

/** 上一曲 */
- (IBAction)pre {
    
    [self.player preOne];
}

#pragma mark - 定时器,刷新进度
- (void)updateProgress {
    
    //设置时间显示进度
    self.currentTime.text = [NSString stringByTimeInterval:self.player.currentTime];
    self.totalTime.text = [NSString stringByTimeInterval:self.player.totalTime];
    
    
    //刷新进度条 (设置滑块的宽度)
    
    self.sliderLeft.width = (self.player.currentTime / self.player.totalTime) * self.sliderRight.width;
    
    self.sliderThumb.centerX = CGRectGetMaxX(self.sliderLeft.frame);
    
}

#pragma mark - 跳转控制器
/** 显示控制器 */
- (void)show {
    
    //通过动画的方式显示出窗口
    [UIView animateWithDuration:0.5 animations:^{
        //
        self.view.transform = CGAffineTransformIdentity;
    }];
}

- (IBAction)back {
    
    //隐藏控制器
    [UIView animateWithDuration:0.5 animations:^{
        //
        self.view.transform = CGAffineTransformMakeTranslation(0, self.view.bounds.size.height);
    }];
}



/** 监听播放状态 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    
    if ([change[@"new"] integerValue] == kQMMusicPlayerStatusPlaying) {
        //
        //改变按钮状态
        [self.playButton setImage:[UIImage imageNamed:@"player_btn_pause_normal"] forState:UIControlStateNormal];
        [self.playButton setImage:[UIImage imageNamed:@"player_btn_pause_highlight"] forState:UIControlStateHighlighted];
                
        //恢复动画
        [self.topView resumeRotation];
        
    } else if ([change[@"new"] integerValue] == kQMMusicPlayerStatusPause) {
        
        //改变按钮状态
        [self.playButton setImage:[UIImage imageNamed:@"player_btn_play_normal"] forState:UIControlStateNormal];
        [self.playButton setImage:[UIImage imageNamed:@"player_btn_play_highlight"] forState:UIControlStateHighlighted];
        
        //暂停动画
        [self.topView pauseRotation];
    }
}


- (void)dealloc {
    
    NSLog(@"%s", __func__);
    
    //移除通知
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    //移除观察者
    [_player removeObserver:self forKeyPath:@"status"];
}


@end
