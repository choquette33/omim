#import "Common.h"
#import "MWMTextToSpeech.h"
#import "Statistics.h"
#import <AVFoundation/AVFoundation.h>

#include "Framework.h"
#include "sound/tts/languages.hpp"

extern NSString * const kUserDefaultsTTSLanguage = @"UserDefaultsTTSLanguage";
extern NSString * const kUserDafaultsNeedToEnableTTS = @"UserDefaultsNeedToEnableTTS";

@interface MWMTextToSpeech()
{
  vector<pair<string, string>> _availableLanguages;
}

@property (nonatomic) AVSpeechSynthesizer * speechSynthesizer;
@property (nonatomic) AVSpeechSynthesisVoice * speechVoice;
@property (nonatomic) float speechRate;

@end

@implementation MWMTextToSpeech

+ (instancetype)tts
{
  static dispatch_once_t onceToken;
  static MWMTextToSpeech * tts = nil;
  dispatch_once(&onceToken, ^
  {
    tts = [[super alloc] initTTS];
  });
  return tts;
}

- (instancetype)initTTS
{
  self = [super init];
  if (self)
  {
    _availableLanguages = availableLanguages();

    NSString * saved = self.savedLanguage;
    string preferedLanguage;
    if (saved.length)
      preferedLanguage = saved.UTF8String;
    else
      preferedLanguage = tts::bcp47ToTwineLanguage([AVSpeechSynthesisVoice currentLanguageCode]);

    pair<string, string> const lan {preferedLanguage, tts::translatedTwine(preferedLanguage)};
    if (find(_availableLanguages.begin(), _availableLanguages.end(), lan) != _availableLanguages.end())
      [self setNotificationsLocale:@(preferedLanguage.c_str())];
    else
      [self setNotificationsLocale:@"en"];
    // Before 9.0 version iOS has an issue with speechRate. AVSpeechUtteranceDefaultSpeechRate does not work correctly.
    // It's a work around for iOS 7.x and 8.x.
    _speechRate = isIOSVersionLessThan(@"7.1.1") ? 0.3 : (isIOSVersionLessThan(@"9.0.0") ? 0.15 : AVSpeechUtteranceDefaultSpeechRate);
  }
  return self;
}

+ (void)activateAudioSession
{
  NSError * err = nil;
  AVAudioSession * audioSession = [AVAudioSession sharedInstance];
  if (![audioSession setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&err])
  {
    LOG(LWARNING, ("[ setCategory]] error.", [err localizedDescription]));
    return;
  }
  if (![audioSession setActive:YES error:&err])
    LOG(LWARNING, ("[[AVAudioSession sharedInstance] setActive]] error.", [err localizedDescription]));
}

- (vector<pair<string, string>>)availableLanguages
{
  return _availableLanguages;
}

- (void)setNotificationsLocale:(NSString *)locale
{
  [[Statistics instance] logEvent:kStatEventName(kStatTTSSettings, kStatChangeLanguage)
                   withParameters:@{kStatValue : locale}];
  NSUserDefaults * ud = [NSUserDefaults standardUserDefaults];
  [ud setObject:locale forKey:kUserDefaultsTTSLanguage];
  [ud synchronize];
  [self createVoice:locale];
}

- (BOOL)isValid
{
  return _speechSynthesizer != nil && _speechVoice != nil;
}

- (BOOL)isNeedToEnable
{
  return [[NSUserDefaults standardUserDefaults] boolForKey:kUserDafaultsNeedToEnableTTS];
}

- (void)setNeedToEnable:(BOOL)need
{
  NSUserDefaults * ud = [NSUserDefaults standardUserDefaults];
  [ud setBool:need forKey:kUserDafaultsNeedToEnableTTS];
  [ud synchronize];
}

- (void)enable
{
  [self setNeedToEnable:YES];
  if (![self isValid])
    [self createSynthesizer];
  GetFramework().EnableTurnNotifications(true);
}

- (void)disable
{
  [self setNeedToEnable:NO];
  GetFramework().EnableTurnNotifications(false);
}

- (BOOL)isEnable
{
  return GetFramework().AreTurnNotificationsEnabled() ? YES : NO;
}

- (NSString *)savedLanguage
{
  return [[NSUserDefaults standardUserDefaults] stringForKey:kUserDefaultsTTSLanguage];
}

- (void)createSynthesizer
{
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
  {
    self.speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
    [self createVoice:self.savedLanguage];
  });
  // TODO(vbykoianko) Use [NSLocale preferredLanguages] instead of [AVSpeechSynthesisVoice currentLanguageCode].
  // [AVSpeechSynthesisVoice currentLanguageCode] is used now because of we need a language code in BCP-47.
}

- (void)createVoice:(NSString *)locale
{
  NSString * const DEFAULT_LANG = @"en-US";

  if (!locale)
  {
    LOG(LERROR, ("locale is nil. Trying default locale."));
    locale = DEFAULT_LANG;
  }
  
  NSArray * availTTSLangs = [AVSpeechSynthesisVoice speechVoices];
  
  if (!availTTSLangs)
  {
    LOG(LERROR, ("No languages for TTS. MWMTextFoSpeech is invalid."));
    return; // self is not valid.
  }
  
  AVSpeechSynthesisVoice * voice = [AVSpeechSynthesisVoice voiceWithLanguage:locale];
  if (!voice || ![availTTSLangs containsObject:voice])
  {
    locale = DEFAULT_LANG;
    AVSpeechSynthesisVoice * voice = [AVSpeechSynthesisVoice voiceWithLanguage:locale];
    if (!voice || ![availTTSLangs containsObject:voice])
    {
      LOG(LERROR, ("The UI language and English are not available for TTS. MWMTestToSpeech is invalid."));
      return; // self is not valid.
    }
  }
  
  self.speechVoice = [AVSpeechSynthesisVoice voiceWithLanguage:locale];
  string const twineLang = tts::bcp47ToTwineLanguage(locale);
  if (twineLang.empty())
  {
    LOG(LERROR, ("Cannot convert UI locale or default locale to twine language. MWMTestToSpeech is invalid."));
    return; // self is not valid.
  }
  GetFramework().SetTurnNotificationsLocale(twineLang);
}

- (void)speakOneString:(NSString *)textToSpeak
{
  if (!textToSpeak || ![textToSpeak length])
    return;
  
  NSLog(@"Speak text: %@", textToSpeak);
  AVSpeechUtterance * utterance = [AVSpeechUtterance speechUtteranceWithString:textToSpeak];
  utterance.voice = self.speechVoice;
  utterance.rate = self.speechRate;
  [self.speechSynthesizer speakUtterance:utterance];
}

- (void)playTurnNotifications
{
  Framework & frm = GetFramework();
  if (!frm.IsRoutingActive())
    return;
  
  vector<string> notifications;
  frm.GenerateTurnNotifications(notifications);

  if (![self isValid])
    return;

  for (auto const & text : notifications)
    [self speakOneString:@(text.c_str())];
}

static vector<pair<string, string>> availableLanguages()
{
  NSArray<AVSpeechSynthesisVoice *> * voices = [AVSpeechSynthesisVoice speechVoices];
  vector<string> native(voices.count);
  for (AVSpeechSynthesisVoice * v in voices)
    native.push_back(tts::bcp47ToTwineLanguage(v.language));

  sort(native.begin(), native.end());
  using namespace routing::turns::sound;
  vector<pair<string, string>> result;
  for (auto const & p : kLanguageList)
  {
    if (find(native.begin(), native.end(), p.first) != native.end())
      result.push_back(p);
  }
  return result;
}

@end

namespace tts
{

string bcp47ToTwineLanguage(NSString const * bcp47LangName)
{
  if (bcp47LangName == nil || [bcp47LangName length] < 2)
    return string("");

  if ([bcp47LangName isEqualToString:@"zh-CN"] || [bcp47LangName isEqualToString:@"zh-CHS"]
      || [bcp47LangName isEqualToString:@"zh-SG"])
  {
    return string("zh-Hans"); // Chinese simplified
  }

  if ([bcp47LangName hasPrefix:@"zh"])
    return string("zh-Hant"); // Chinese traditional

  // Taking two first symbols of a language name. For example ru-RU -> ru
  return [[bcp47LangName substringToIndex:2] UTF8String];
}

string translatedTwine(string const & twine)
{
  auto const & list = routing::turns::sound::kLanguageList;
  auto const it = find_if(list.begin(), list.end(), [&twine](pair<string, string> const & pair)
  {
    return pair.first == twine;
  });
  
  if (it != list.end())
    return it->second;
  else
    return "";
}

} // namespace tts