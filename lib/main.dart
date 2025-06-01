import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const WorkoutTimerApp());
  });
}

class WorkoutTimerApp extends StatelessWidget {
  const WorkoutTimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cronus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: const Color.fromARGB(255, 9, 33, 252),
        colorScheme: const ColorScheme.dark(primary: Color.fromARGB(255, 255, 255, 255)),
      ),
      home: const WorkoutTimerPage(),
    );
  }
}

class WorkoutTimerPage extends StatefulWidget {
  const WorkoutTimerPage({super.key});

  @override
  _WorkoutTimerPageState createState() => _WorkoutTimerPageState();
}

class _WorkoutTimerPageState extends State<WorkoutTimerPage> {
  int rounds = 3;
  int exerciseTime = 30;
  int restTime = 15;

  int currentRound = 0;
  int secondsLeft = 0;
  bool isExercise = true;
  bool isResting = false;
  bool isTransitioning = false;
  bool isRunning = false;
  bool isWorkoutComplete = false;
  Timer? timer;


  final AudioPlayer _beepPlayer = AudioPlayer();
  final AudioPlayer _inicioTreinoPlayer = AudioPlayer();
  final AudioPlayer _contagemSegundosPlayer = AudioPlayer();
  final AudioPlayer _inicioDescansoPlayer = AudioPlayer();
  final AudioPlayer _finalParabensPlayer = AudioPlayer();
  
  
  bool _soundsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSounds();
  }

  @override
  void dispose() {
    timer?.cancel();
    _beepPlayer.dispose();
    _inicioTreinoPlayer.dispose();
    _contagemSegundosPlayer.dispose();
    _inicioDescansoPlayer.dispose();
    _finalParabensPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadSounds() async {
    try {
    
      await AudioPlayer.global.setGlobalAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            contentType: AndroidContentType.music,
            isSpeakerphoneOn: true,
            stayAwake: true,
            usageType: AndroidUsageType.alarm,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: [
              AVAudioSessionOptions.mixWithOthers,
              AVAudioSessionOptions.duckOthers,
            ],
          ),
        ),
      );
      
    
      final players = [
        _beepPlayer, 
        _inicioTreinoPlayer, 
        _contagemSegundosPlayer, 
        _inicioDescansoPlayer,
        _finalParabensPlayer
      ];
      
      for (final player in players) {
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setVolume(1.0);
      }
      
      setState(() {
        _soundsLoaded = true;
      });
      
      debugPrint('Sons carregados com sucesso');
    } catch (e) {
      debugPrint('Erro ao configurar áudio: $e');
    }
  }

  Future<void> _playSound(AudioPlayer player, String soundPath) async {
    if (!_soundsLoaded) return;
    
    try {
      await player.stop();
      await player.play(AssetSource(soundPath));
    } catch (e) {
      debugPrint('Erro ao reproduzir som ($soundPath): $e');
    }
  }

  Future<void> _playBeep() async {
    await _playSound(_beepPlayer, 'sounds/countdown_1.mp3');
  }

  Future<void> _playInicioTreino() async {
    await _playSound(_inicioTreinoPlayer, 'sounds/inicio_treino.mp3');
  }

  Future<void> _playContagemSegundos() async {
    await _playSound(_contagemSegundosPlayer, 'sounds/contagem_segundos.mp3');
  }

  Future<void> _playInicioDescanso() async {
    await _playSound(_inicioDescansoPlayer, 'sounds/inicio_descanso.mp3');
  }

  Future<void> _playFinalParabens() async {
    await _playSound(_finalParabensPlayer, 'sounds/final_parabens.mp3');
  }

  void startWorkout() async {
    setState(() {
      currentRound = 1;
      isExercise = true;
      isResting = false;
      isTransitioning = false;
      isWorkoutComplete = false;
      secondsLeft = exerciseTime;
      isRunning = true;
    });
    

    await Future.delayed(Duration(milliseconds: 100));
    await _playInicioTreino();
    
    startTimer();
  }

  void startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      
      if (isTransitioning) {
        if (secondsLeft == 0) {
          setState(() {
            isTransitioning = false;
            isExercise = false;
            isResting = true;
            secondsLeft = restTime;
          });
          
        
          await Future.delayed(Duration(milliseconds: 100));
          await _playInicioDescanso();
        } else {
          setState(() => secondsLeft--);
          
        }
        return;
      }
      
    
      if (isWorkoutComplete) {
        timer.cancel();
        return;
      }

      if (secondsLeft == 0) {
        if (isExercise) {
          
          await _playBeep();
          
        
          setState(() {
            isTransitioning = true;
            secondsLeft = 3; 
          });
        } else if (isResting) {
          
          if (currentRound < rounds) {
            
            await _playBeep();
            
            setState(() {
              isExercise = true;
              isResting = false;
              currentRound++;
              secondsLeft = exerciseTime;
            });
            
            
            await Future.delayed(Duration(milliseconds: 300));
            await _playInicioTreino();
          } else {
            
            timer.cancel();
            
            setState(() {
              isRunning = false;
              isWorkoutComplete = true;
            });
            
            
            await Future.delayed(Duration(milliseconds: 100));
            await _playFinalParabens();
          }
        }
      } else {
        setState(() => secondsLeft--);
        
        
        if (isExercise || isResting) { 
          
          if (secondsLeft <= 5 && secondsLeft > 0) {
            if (
             
              (isExercise && secondsLeft <= 5) ||
              
              (isResting && secondsLeft <= 5)
            ) {
              await _playContagemSegundos();
            }
          }
        }
      }
    });
  }

  void pauseWorkout() {
    timer?.cancel();
    setState(() {
      isRunning = false;
    });
  }

  void resumeWorkout() {
    setState(() {
      isRunning = true;
    });
    startTimer();
  }

  void resetWorkout() {
    timer?.cancel();
    setState(() {
      isRunning = false;
      isWorkoutComplete = false;
      currentRound = 0;
      secondsLeft = 0;
      isExercise = true;
      isResting = false;
      isTransitioning = false;
    });
  }

  void resetCurrentPhase() {
    setState(() {
      if (isTransitioning) {
        secondsLeft = 3;
      } else if (isExercise) {
        secondsLeft = exerciseTime;
      } else if (isResting) {
        secondsLeft = restTime;
      }
    });
  }

  void _showPicker(BuildContext context, String label, int currentValue, Function(int) onChanged) {
    int min = label == 'Rodadas' ? 1 : 1;
    int max = label == 'Rodadas' ? 20 : 180;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 250,
          color: Colors.black,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onChanged(currentValue);
                    },
                    child: const Text('Confirmar', style: TextStyle(color: Color.fromARGB(255, 0, 21, 209))),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoPicker(
                  backgroundColor: Colors.black,
                  itemExtent: 50,
                  scrollController: FixedExtentScrollController(
                    initialItem: currentValue - min,
                  ),
                  onSelectedItemChanged: (int index) {
                    currentValue = index + min;
                  },
                  children: List<Widget>.generate(max - min + 1, (int index) {
                    return Center(
                      child: Text(
                        '${index + min}',
                        style: const TextStyle(color: Colors.white, fontSize: 24),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildTimeSelector(String label, int value, Function(int) onChanged) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showPicker(context, label, value, onChanged),
          child: Container(
            width: 120,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(90),
              color: const Color.fromARGB(255, 16, 0, 165).withOpacity(0.2),
              border: Border.all(color: const Color.fromARGB(255, 19, 0, 194), width: 1.5),
            ),
            child: Center(
              child: Text(
                '$value',
                style: const TextStyle(fontSize: 28, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cronus Timer'),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: isRunning || currentRound > 0 || isWorkoutComplete
                ? _buildControlPanel()
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      buildTimeSelector('Rodadas', rounds, (v) => setState(() => rounds = v)),
                      const SizedBox(height: 20),
                      buildTimeSelector('Exercício', exerciseTime, (v) => setState(() => exerciseTime = v)),
                      const SizedBox(height: 20),
                      buildTimeSelector('Descanso', restTime, (v) => setState(() => restTime = v)),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: startWorkout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 0, 10, 148),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(60),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Iniciar Treino', style: TextStyle(fontSize: 20)),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    if (isWorkoutComplete) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Treino Concluído!',
            style: TextStyle(fontSize: 32, color: Color.fromARGB(255, 15, 12, 219), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text(
            'Parabéns pelo seu esforço!',
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: resetWorkout,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 0, 10, 148),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(60),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Voltar ao Início', style: TextStyle(fontSize: 20)),
          ),
        ],
      );
    }
    
    String statusText = 'Exercício';
    if (isTransitioning) {
      statusText = 'Preparando...';
    } else if (isResting) {
      statusText = 'Descanso';
    }
    
    return Column(
      children: [
        Text(
          statusText,
          style: const TextStyle(fontSize: 24, color: Color.fromARGB(255, 15, 12, 219)),
        ),
        const SizedBox(height: 8),
        Text(
          'Rodada: $currentRound / $rounds',
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 8),
        Text(
          '$secondsLeft s',
          style: const TextStyle(fontSize: 48, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(isRunning ? Icons.pause : Icons.play_arrow),
              onPressed: isRunning ? pauseWorkout : resumeWorkout,
            ),
            const SizedBox(width: 24),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: resetCurrentPhase,
            ),
            const SizedBox(width: 24),
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: resetWorkout,
            ),
          ],
        ),
      ],
    );
  }
}