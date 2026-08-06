import 'package:flutter_test/flutter_test.dart';
import 'package:wing/shared/voice/voice_text_language_detector.dart';

void main() {
  final detector = DefaultVoiceTextLanguageDetector();

  test('identifies common incoming reply languages', () {
    expect(
      detector.detect(
        'Hello. I can help you with your question and explain the answer clearly.',
      ),
      'en',
    );
    expect(detector.detect('Hola, ¿cómo puedo ayudarte hoy?'), 'es');
    expect(detector.detect('Bonjour, comment puis-je vous aider ?'), 'fr');
    expect(
      detector.detect(
        'Hola, puedo ayudarte a explicar la respuesta claramente.',
      ),
      'es',
    );
    expect(
      detector.detect(
        'Ciao, posso aiutarti a spiegare chiaramente la risposta.',
      ),
      'it',
    );
    expect(detector.detect('こんにちは、お手伝いできますか？'), 'ja');
    expect(detector.detect('مرحبا، كيف يمكنني مساعدتك اليوم؟'), 'ar');
    expect(detector.detect('Привет, чем я могу вам помочь сегодня?'), 'ru');
    expect(detector.detect('नमस्ते, मैं आज आपकी कैसे मदद कर सकता हूँ?'), 'hi');
    expect(
      detector.detect(
        'Hallo, ik kan u vandaag helpen met uw vraag en het antwoord uitleggen.',
      ),
      'nl',
    );
    expect(
      detector.detect(
        'Merhaba, bugün sorunuz konusunda size yardımcı olabilirim.',
      ),
      'tr',
    );
    expect(
      detector.detect(
        'Hej, jeg kan hjælpe dig med dit spørgsmål og forklare svaret tydeligt.',
      ),
      'da',
    );
    expect(
      detector.detect(
        'Hei, jeg kan hjelpe deg med spørsmålet og forklare svaret tydelig.',
      ),
      'no',
    );
    expect(
      detector.detect(
        'Привіт, я можу допомогти вам із запитанням і пояснити відповідь.',
      ),
      'uk',
    );
    expect(
      detector.detect('سلام، می‌توانم امروز در پاسخ به سؤال شما کمک کنم.'),
      'fa',
    );
    expect(
      detector.detect(
        'سلام، میں آج آپ کے سوال کا جواب دینے میں مدد کر سکتا ہوں۔',
      ),
      'ur',
    );
    expect(
      detector.detect(
        'नमस्कार, मी आज तुमच्या प्रश्नाचे उत्तर देण्यास मदत करू शकतो.',
      ),
      'mr',
    );
    expect(
      detector.detect(
        'Dobrý den, dnes vám mohu pomoci odpovědět na otázku a vše vysvětlit.',
      ),
      'cs',
    );
    expect(
      detector.detect(
        'Halo, saya dapat membantu menjawab pertanyaan Anda dan menjelaskan jawabannya hari ini.',
      ),
      'id',
    );
    expect(
      detector.detect(
        'Helo, saya boleh membantu menjawab soalan anda dan menerangkan jawapannya hari ini.',
      ),
      'ms',
    );
    expect(
      detector.detect(
        'Bună ziua, vă pot ajuta să răspundeți la întrebare și să explic răspunsul clar.',
      ),
      'ro',
    );
    expect(
      detector.detect(
        'Dobrý deň, dnes vám môžem pomôcť odpovedať na otázku a všetko vysvetliť.',
      ),
      'sk',
    );
    expect(
      detector.detect(
        'Pozdravljeni, danes vam lahko pomagam odgovoriti na vprašanje in jasno razložiti odgovor.',
      ),
      'sl',
    );
    expect(
      detector.detect(
        'Здравейте, днес мога да ви помогна да отговорите на въпроса и да обясня отговора ясно.',
      ),
      'bg',
    );
    expect(
      detector.detect(
        'Здраво, данас могу да вам помогнем да одговорите на питање и јасно објасним одговор.',
      ),
      'sr',
    );
    expect(
      detector.detect(
        'Përshëndetje, sot mund t’ju ndihmoj t’i përgjigjeni pyetjes dhe ta shpjegoj qartë përgjigjen.',
      ),
      'sq',
    );
    expect(
      detector.detect(
        'Halló, ég get hjálpað þér að svara spurningunni og útskýra svarið skýrt í dag.',
      ),
      'is',
    );
    expect(
      detector.detect(
        'வணக்கம், இன்று உங்கள் கேள்விக்கு பதிலளிக்கவும் தெளிவாக விளக்கவும் நான் உதவ முடியும்.',
      ),
      'ta',
    );
    expect(
      detector.detect(
        'నమస్కారం, ఈ రోజు మీ ప్రశ్నకు సమాధానం ఇవ్వడానికి మరియు స్పష్టంగా వివరించడానికి నేను సహాయం చేయగలను.',
      ),
      'te',
    );
    expect(
      detector.detect(
        'ನಮಸ್ಕಾರ, ಇಂದು ನಿಮ್ಮ ಪ್ರಶ್ನೆಗೆ ಉತ್ತರಿಸಲು ಮತ್ತು ಸ್ಪಷ್ಟವಾಗಿ ವಿವರಿಸಲು ನಾನು ಸಹಾಯ ಮಾಡಬಹುದು.',
      ),
      'kn',
    );
    expect(
      detector.detect(
        'നമസ്കാരം, ഇന്ന് നിങ്ങളുടെ ചോദ്യത്തിന് ഉത്തരം നൽകാനും വ്യക്തമായി വിശദീകരിക്കാനും എനിക്ക് സഹായിക്കാനാകും.',
      ),
      'ml',
    );
    expect(
      detector.detect(
        'ආයුබෝවන්, අද ඔබගේ ප්‍රශ්නයට පිළිතුරු දීමට සහ පැහැදිලි කිරීමට මට උදව් කළ හැකිය.',
      ),
      'si',
    );
    expect(
      detector.detect(
        'សួស្តី ខ្ញុំអាចជួយឆ្លើយសំណួររបស់អ្នក និងពន្យល់ចម្លើយឱ្យច្បាស់នៅថ្ងៃនេះ។',
      ),
      'km',
    );
    expect(
      detector.detect(
        'ສະບາຍດີ, ຂ້ອຍສາມາດຊ່ວຍຕອບຄຳຖາມ ແລະອະທິບາຍຄຳຕອບໃຫ້ຊັດເຈນໄດ້.',
      ),
      'lo',
    );
    expect(
      detector.detect(
        'မင်္ဂလာပါ၊ ယနေ့ သင့်မေးခွန်းကို ဖြေဆိုပြီး အဖြေကို ရှင်းလင်းစွာ ရှင်းပြနိုင်ပါသည်။',
      ),
      'my',
    );
    expect(
      detector.detect(
        'გამარჯობა, დღეს შემიძლია დაგეხმაროთ კითხვაზე პასუხის გაცემაში და პასუხის ნათლად ახსნაში.',
      ),
      'ka',
    );
    expect(
      detector.detect(
        'Salam, bu gün sualınıza cavab verməyə və cavabı aydın izah etməyə kömək edə bilərəm.',
      ),
      'az',
    );
    expect(
      detector.detect(
        'Ola, hoxe podo axudarche a responder a pregunta e explicar claramente a resposta.',
      ),
      'gl',
    );
    expect(
      detector.detect(
        'Сәлем, бүгін сұрағыңызға жауап беруге және жауабын анық түсіндіруге көмектесе аламын.',
      ),
      'kk',
    );
    expect(
      detector.detect(
        'Сайн байна уу, өнөөдөр таны асуултад хариулж, хариултыг тодорхой тайлбарлахад тусалж чадна.',
      ),
      'mn',
    );
    expect(
      detector.detect(
        'नमस्कार, म आज तपाईंको प्रश्नको उत्तर दिन र स्पष्ट रूपमा व्याख्या गर्न मद्दत गर्न सक्छु।',
      ),
      'ne',
    );
  });

  test('canonical Unicode forms produce the same language', () {
    expect(detector.detect('Olá, você pode me ajudar hoje?'), 'pt');
    expect(detector.detect('Olá, você pode me ajudar hoje?'), 'pt');
    expect(detector.detect('Halló, ég get hjálpað þér í dag.'), 'is');
    expect(detector.detect('Halló, ég get hjálpað þér í dag.'), 'is');
    expect(detector.detect('Bună ziua, vă pot ajuta astăzi.'), 'ro');
    expect(detector.detect('Bună ziua, vă pot ajuta astăzi.'), 'ro');
  });

  test('native-script digits do not determine prose language', () {
    expect(detector.detect('The answer is ready ௧௨௩௪௫௬௭௮௯௦.'), 'en');
    expect(detector.detect('The answer is ready ౧౨౩౪౫౬౭౮౯౦.'), 'en');
    expect(detector.detect('The answer is ready ೧೨೩೪೫೬೭೮೯೦.'), 'en');
  });

  test('identifies short replies with strong language signals', () {
    expect(detector.detect('Hola, ¿cómo estás?'), 'es');
    expect(detector.detect('Je peux vous aider.'), 'fr');
    expect(detector.detect('こんにちは'), 'ja');
    expect(detector.detect('Dobrý den, mohu vám dnes pomoci.'), 'cs');
    expect(detector.detect('Dobrý deň, môžem vám dnes pomôcť.'), 'sk');
    expect(detector.detect('Привет, могу вам помочь.'), 'ru');
    expect(detector.detect('Здраво, могу да вам помогнем.'), 'sr');
  });

  test('ignores Markdown code when selecting the reply language', () {
    const prose = '你好，我可以清楚详细地解释这个答案。\n';
    expect(
      detector.detect(
        '$prose```dart\nFuture<void> resetToDefaultVoice() async {}\n```',
      ),
      'zh',
    );
    expect(
      detector.detect(
        '$prose~~~dart\nFuture<void> resetToDefaultVoice() async {}\n~~~',
      ),
      'zh',
    );
    expect(
      detector.detect('$prose    Future<void> resetToDefaultVoice() async {}'),
      'zh',
    );
    expect(
      detector.detect(
        'The result is ready now. ``привет помочь сегодня ответ``',
      ),
      'en',
    );
  });

  test('ignores absolute file paths when selecting the reply language', () {
    expect(
      detector.detect(
        '你好，我可以清楚详细地解释这个答案。 '
        '/path/to/english_named_configuration_file.json',
      ),
      'zh',
    );
    expect(
      detector.detect(
        r'The result is ready now. \\сервер\ответ\помощь\сегодня.txt',
      ),
      'en',
    );
    expect(
      detector.detect(
        r'The result is ready now. (\\сервер\привет\помочь\сегодня\ответ.txt)',
      ),
      'en',
    );
  });

  test('ignores email addresses when selecting the reply language', () {
    expect(detector.detect('你好，我可以清楚详细地解释这个答案。 support@example.com'), 'zh');
    expect(
      detector.detect(
        'This is the correct answer. ответ.помощь.сегодня@пример.рус',
      ),
      'en',
    );
    expect(
      detector.detect(
        'This is the correct answer. مساعدة.مرحبا.اليوم@مثال.عرب',
      ),
      'en',
    );
  });

  test('ignores URLs when selecting the reply language', () {
    expect(detector.detect('你好，我可以清楚详细地解释这个答案。 https://example.com/a/b'), 'zh');
    expect(
      detector.detect(
        'The result is ready now. www.привет-помочь-сегодня-ответ.рус',
      ),
      'en',
    );
    expect(
      detector.detect(
        'The result is ready now. ftp://привет-помочь-сегодня-ответ.рус/file',
      ),
      'en',
    );
    expect(
      detector.detect(
        'The result is ready now. привет-помочь-сегодня-ответ.рус/path',
      ),
      'en',
    );
    expect(
      detector.detect(
        'The result is ready now. example.рус?привет-помочь-сегодня-ответ',
      ),
      'en',
    );
    expect(
      detector.detect(
        'The result is ready now. example.рус#привет-помочь-сегодня-ответ',
      ),
      'en',
    );
    expect(
      detector.detect(
        'The result is ready now. example.рус:8080/привет-помочь-сегодня-ответ',
      ),
      'en',
    );
  });

  test('uses English for instructions that mention foreign words', () {
    expect(detector.detect('Use hola and gracias.'), 'en');
    expect(detector.detect('Say bonjour and merci.'), 'en');
    expect(detector.detect('Compare ciao and grazie.'), 'en');
    expect(detector.detect('Say hola in English.'), 'en');
    expect(detector.detect('The word hjälp means help in English.'), 'en');
    expect(detector.detect('Explain what привет means in English.'), 'en');
  });

  test('uses the dominant language when a reply quotes foreign text', () {
    expect(
      detector.detect(
        'The Japanese greeting is こんにちは, which means hello in English.',
      ),
      'en',
    );
    expect(
      detector.detect('In French, je peux vous aider means I can help you.'),
      isNull,
    );
    expect(
      detector.detect(
        'Here is the requested translation and a short explanation:\n'
        '> Hola, ¿cómo estás? Muchas gracias por tu ayuda.',
      ),
      'en',
    );
    expect(
      detector.detect(
        'The translated sentence appears below for reference:\n'
        '> Bonjour, je peux vous aider et expliquer la réponse.',
      ),
      'en',
    );
    expect(detector.detect('> Hola, ¿cómo estás?'), 'es');
    expect(
      detector.detect(
        'Spanish translation:\n'
        '> Hola, muchas gracias por tu ayuda. Puedo explicar la respuesta claramente y responder todas tus preguntas hoy.',
      ),
      'es',
    );
    expect(
      detector.detect(
        'French translation:\n'
        '> Bonjour, merci beaucoup pour votre aide. Je peux expliquer clairement la réponse et répondre à toutes vos questions.',
      ),
      'fr',
    );
  });

  test('keeps the device TTS language for ambiguous short text', () {
    expect(detector.detect('2'), isNull);
    expect(detector.detect('ok'), isNull);
    expect(detector.detect('😀😀😀😀😀😀😀😀😀😀😀😀 ok'), isNull);
    expect(detector.detect('Hello, how can I help you today?'), isNull);
  });
}
