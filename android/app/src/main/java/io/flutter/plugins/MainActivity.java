import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.flutter_plugin_android_lifecycle.FlutterAndroidLifecyclePlugin;
import com.almond.vosk.Vosk;
import com.almond.vosk.Recognizer;

public class MainActivity extends FlutterActivity {
  private static final String CHANNEL = "com.example.voice_assistant";
  private Recognizer recognizer;

  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    super.configureFlutterEngine(flutterEngine);

    new MethodChannel(flutterEngine.getDartExecutor(), CHANNEL).setMethodCallHandler(
      (call, result) -> {
        if (call.method.equals("startListening")) {
          startListening();
        } else if (call.method.equals("stopListening")) {
          stopListening();
        } else {
          result.notImplemented();
        }
      }
    );
  }

  private void startListening() {
    // Initialize recognizer with Vosk API
    recognizer = new Recognizer();
    recognizer.startListening();
  }

  private void stopListening() {
    if (recognizer != null) {
      recognizer.stopListening();
    }
  }
}
