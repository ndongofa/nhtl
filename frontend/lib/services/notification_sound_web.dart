// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void playNotificationSound() {
  try {
    final script = html.ScriptElement();
    script.text = '''
      (function() {
        try {
          var AudioCtx = window.AudioContext || window.webkitAudioContext;
          if (!AudioCtx) return;
          var ctx = new AudioCtx();
          function beep(startTime, freq, duration, volume) {
            var osc  = ctx.createOscillator();
            var gain = ctx.createGain();
            osc.connect(gain);
            gain.connect(ctx.destination);
            osc.type            = 'sine';
            osc.frequency.value = freq;
            gain.gain.setValueAtTime(volume, startTime);
            gain.gain.exponentialRampToValueAtTime(0.001, startTime + duration);
            osc.start(startTime);
            osc.stop(startTime + duration + 0.05);
          }
          var t = ctx.currentTime;
          beep(t,        784,  0.15, 1.0);
          beep(t + 0.20, 1047, 0.15, 1.0);
          beep(t + 0.40, 1319, 0.22, 1.0);
          setTimeout(function() { ctx.close(); }, 1200);
        } catch(e) {
          console.warn('[NotificationSound] Web Audio error:', e);
        }
      })();
    ''';
    html.document.head!.append(script);
    Future.delayed(const Duration(milliseconds: 200), () {
      try {
        script.remove();
      } catch (_) {}
    });
  } catch (e) {
    print('[NotificationSound] dart:html error: $e');
  }
}
