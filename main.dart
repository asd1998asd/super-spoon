import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const MaterialApp(
    home: Directionality(
      textDirection: TextDirection.rtl, // لدعم اللغة العربية
      child: StartScreen(),
    ),
    debugShowCheckedModeBanner: false,
  ));
}

// ================== شاشة البداية ==================
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🃏 جواكر', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            const Text('جاهز للعب؟', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GameScreen()),
                );
              },
              child: const Text('ابدأ اللعبة', style: TextStyle(fontSize: 22)),
            ),
          ],
        ),
      ),
    );
  }
}

// ================== شاشة اللعبة ==================
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameEngine engine;
  bool waitingForDraw = true;
  GameCard? selectedCard;
  List<Move> moves = [];
  String message = 'دورك — اسحب ورقة';

  @override
  void initState() {
    super.initState();
    engine = GameEngine();
    engine.newGame();
  }

  void selectCard(GameCard c) {
    setState(() {
      selectedCard = c;
      moves = engine.validMoves(c);
      message = moves.isEmpty ? 'لا يمكن لعبها' : 'اختر حركة';
    });
  }

  void applyMove(Move m) {
    engine.applyMove(m);
    if (engine.gameOver) return endGame();
    if (engine.current.hand.length > 5) engine.discardCard(engine.current.hand.last);
    engine.endTurn();
    nextTurn();
  }

  void draw(bool fromDiscard) {
    fromDiscard ? engine.drawFromDiscard() : engine.drawFromDeck();
    setState(() {
      waitingForDraw = false;
      message = 'اختر ورقة';
      selectedCard = null;
      moves = [];
    });
  }

  void nextTurn() {
    if (engine.current.isHuman) {
      setState(() {
        waitingForDraw = true;
        selectedCard = null;
        moves = [];
        message = 'دورك';
      });
    } else {
      setState(() => message = '${engine.current.name} يلعب...');
      Future.delayed(const Duration(milliseconds: 800), aiTurn);
    }
  }

  void aiTurn() {
    if (engine.gameOver) return;
    engine.drawFromDeck();
    final m = engine.aiChooseMove();
    if (m != null) engine.applyMove(m);
    if (engine.gameOver) return endGame();
    if (engine.current.hand.length > 5) engine.discardCard(engine.current.hand.last);
    engine.endTurn();
    nextTurn();
  }

  void endGame() {
    setState(() {
      message = engine.winnerTeam == 0 ? '🎉 فزت أنت وشريكك!' : '😢 فاز الخصوم';
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(engine.winnerTeam == 0 ? '🎉 فزت!' : '😢 خسرت'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); 
            },
            child: const Text('القائمة الرئيسية'),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🃏 جواكر'), centerTitle: true),
      body: Column(
        children: [
          Container(
            height: 300,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[800],
              borderRadius: BorderRadius.circular(12)
            ),
            child: Column(
              children: [
                Expanded(child: row(engine.players[2])),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: col(engine.players[3])),
                      Expanded(child: col(engine.players[1]))
                    ]
                  )
                ),
                Expanded(child: row(engine.players[0])),
              ]
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.blue[50],
                    child: Text(message, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                  ),
                  if (waitingForDraw && engine.current.isHuman)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          ElevatedButton(
                            onPressed: () => draw(false),
                            child: Text('اسحب من الكومة (${engine.deck.length})')
                          ),
                          ElevatedButton(
                            onPressed: engine.discard.length > 1 ? () => draw(true) : null,
                            child: Text('من المرمية (${engine.discard.last.label})')
                          ),
                        ]
                      )
                    ),
                  if (!waitingForDraw && engine.current.isHuman) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: engine.current.hand.map((c) => GestureDetector(
                        onTap: () => selectCard(c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: selectedCard == c ? Colors.yellow : Colors.white,
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(6)
                          ),
                          child: Text(c.label, style: TextStyle(fontSize: 20, color: c.isRed ? Colors.red : Colors.black)),
                        ),
                      )).toList()
                    ),
                    const SizedBox(height: 8),
                    ...moves.map((m) => Padding(
                      padding: const EdgeInsets.all(4),
                      child: ElevatedButton(
                        onPressed: () => applyMove(m),
                        child: Text(
                          m.type == MoveType.exitBase
                              ? 'أخرج بيدق ${m.pawnIndex + 1}'
                              : m.type == MoveType.advance
                                  ? 'حرّك بيدق ${m.pawnIndex + 1} بـ ${m.card.forwardSteps}'
                                  : 'بدّل بيدق ${m.pawnIndex + 1} مع خصم ${m.otherPawnIndex! + 1}'
                        ),
                      )
                    )),
                  ],
                ]
              )
            )
          ),
        ]
      ),
    );
  }

  Widget row(Player p) => Container(
    color: engine.currentIndex == p.index ? Colors.yellow[200] : null,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        ...p.pawns.map((pw) => Container(
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: pw.isHome ? Colors.amber : pw.isInHomeStretch ? Colors.orange : pw.isOnTrack ? Colors.blue : Colors.grey,
            borderRadius: BorderRadius.circular(4)
          ),
          child: Text(
            pw.isInBase ? '🏠' : pw.isHome ? '🏁' : '${pw.progress}',
            style: const TextStyle(fontSize: 10, color: Colors.white)
          )
        )),
      ]
    ),
  );

  Widget col(Player p) => Container(
    color: engine.currentIndex == p.index ? Colors.yellow[200] : null,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: p.pawns.map((pw) => Container(
            margin: const EdgeInsets.all(1),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: pw.isHome ? Colors.amber : pw.isInHomeStretch ? Colors.orange : pw.isOnTrack ? Colors.blue : Colors.grey,
              borderRadius: BorderRadius.circular(4)
            ),
            child: Text(
              pw.isInBase ? '🏠' : pw.isHome ? '🏁' : '${pw.progress}',
              style: const TextStyle(fontSize: 9, color: Colors.white)
            )
          )).toList()
        ),
      ]
    ),
  );
}

// ================== منطق اللعبة ==================
enum Suit { hearts, diamonds, clubs, spades, joker }

class GameCard {
  final Suit suit; 
  final int rank; 
  final bool isJoker;
  
  const GameCard(this.suit, this.rank, {this.isJoker = false});
  factory GameCard.joker() => const GameCard(Suit.joker, 0, isJoker: true);
  
  String get label {
    if (isJoker) return '🃏';
    final r = {1: 'A', 11: 'J', 12: 'Q', 13: 'K'}[rank]?.toString() ?? '$rank';
    final s = {Suit.hearts: '♥', Suit.diamonds: '♦', Suit.clubs: '♣', Suit.spades: '♠'}[suit]!;
    return '$r$s';
  }
  
  int get forwardSteps => isJoker ? 13 : (rank == 4 ? -4 : rank);
  bool get canExitBase => isJoker || rank == 1 || rank == 13;
  bool get isJack => !isJoker && rank == 11;
  bool get isRed => suit == Suit.hearts || suit == Suit.diamonds;
}

class Pawn {
  int progress;
  Pawn({this.progress = -1});
  bool get isInBase => progress == -1;
  bool get isHome => progress == 57;
  bool get isOnTrack => progress >= 0 && progress <= 51;
  bool get isInHomeStretch => progress >= 52 && progress <= 56;
  bool canAdvance(int s) => !isHome && !isInBase && progress + s >= 0 && progress + s <= 57;
  void advance(int s) => progress += s;
}

class Player {
  final String name; 
  final int index; 
  final bool isHuman;
  final List<Pawn> pawns = List.generate(4, (_) => Pawn());
  final List<GameCard> hand = [];
  
  Player({required this.name, required this.index, required this.isHuman});
  int get startPos => index * 13;
}

enum MoveType { exitBase, advance, swap }

class Move {
  final MoveType type; 
  final Player player; 
  final int pawnIndex;
  final GameCard card; 
  final Player? other; 
  final int? otherPawnIndex;
  
  Move({
    required this.type, 
    required this.player, 
    required this.pawnIndex,
    required this.card, 
    this.other, 
    this.otherPawnIndex
  });
}

class GameEngine {
  final List<Player> players;
  final List<GameCard> deck = [];
  final List<GameCard> discard = [];
  int currentIndex = 0;
  bool gameOver = false;
  int? winnerTeam;
  final Random r = Random();

  GameEngine() : players = [
    Player(name: 'أنت', index: 0, isHuman: true),
    Player(name: 'خصم 1', index: 1, isHuman: false),
    Player(name: 'شريكك', index: 2, isHuman: false),
    Player(name: 'خصم 2', index: 3, isHuman: false),
  ];

  Player get current => players[currentIndex];

  void newGame() {
    deck.clear();
    for (var s in [Suit.hearts, Suit.diamonds, Suit.clubs, Suit.spades]) {
      for (var rk = 1; rk <= 13; rk++) {
        deck.add(GameCard(s, rk));
      }
    }
    deck.add(GameCard.joker()); 
    deck.add(GameCard.joker());
    deck.shuffle(r);
    discard.clear();
    
    for (var p in players) {
      p.hand.clear();
      for (var i = 0; i < 5; i++) {
        p.hand.add(deck.removeLast());
      }
      for (var pw in p.pawns) {
        pw.progress = -1;
      }
    }
    discard.add(deck.removeLast());
  }

  void drawFromDeck() { 
    if (deck.isEmpty) return; 
    current.hand.add(deck.removeLast()); 
  }
  
  void drawFromDiscard() { 
    if (discard.length > 1) current.hand.add(discard.removeLast()); 
  }
  
  void discardCard(GameCard c) { 
    current.hand.remove(c); 
    discard.add(c); 
  }

  List<Move> validMoves(GameCard c) {
    final m = <Move>[]; 
    final p = current;
    
    if (c.canExitBase) {
      for (var i = 0; i < p.pawns.length; i++) {
        if (p.pawns[i].isInBase) {
          m.add(Move(type: MoveType.exitBase, player: p, pawnIndex: i, card: c));
        }
      }
    }
    
    if (c.isJack) {
      for (var i = 0; i < p.pawns.length; i++) {
        if (p.pawns[i].isOnTrack && p.pawns[i].canAdvance(11)) {
          m.add(Move(type: MoveType.advance, player: p, pawnIndex: i, card: c));
        }
      }
      for (var i = 0; i < p.pawns.length; i++) {
        if (p.pawns[i].isOnTrack) {
          for (var op in players) { 
            if (op.index == p.index) continue;
            for (var j = 0; j < op.pawns.length; j++) {
              if (op.pawns[j].isOnTrack) {
                m.add(Move(type: MoveType.swap, player: p, pawnIndex: i, card: c, other: op, otherPawnIndex: j));
              }
            }
          }
        }
      }
    } else {
      for (var i = 0; i < p.pawns.length; i++) {
        final pw = p.pawns[i];
        if (pw.isInBase || pw.isHome) continue;
        if (pw.canAdvance(c.forwardSteps)) {
          m.add(Move(type: MoveType.advance, player: p, pawnIndex: i, card: c));
        }
      }
    }
    return m;
  }

  void applyMove(Move mv) {
    switch (mv.type) {
      case MoveType.exitBase: 
        mv.player.pawns[mv.pawnIndex].progress = 0; 
        break;
      case MoveType.advance: 
        mv.player.pawns[mv.pawnIndex].advance(mv.card.forwardSteps); 
        break;
      case MoveType.swap:
        final otherPlayer = mv.other!; // إصلاح الخطأ هنا
        final a = mv.player.pawns[mv.pawnIndex]; 
        final b = otherPlayer.pawns[mv.otherPawnIndex!];
        final aAbs = (mv.player.startPos + a.progress) % 52; 
        final bAbs = (otherPlayer.startPos + b.progress) % 52;
        a.progress = (bAbs - mv.player.startPos + 52) % 52; 
        b.progress = (aAbs - otherPlayer.startPos + 52) % 52;
        break;
    }
    mv.player.hand.remove(mv.card); 
    discard.add(mv.card);
    
    for (var t = 0; t < 2; t++) {
      if (players[t].pawns.every((p) => p.isHome) && players[t + 2].pawns.every((p) => p.isHome)) {
        gameOver = true; 
        winnerTeam = t; 
        return;
      }
    }
  }

  void endTurn() => currentIndex = (currentIndex + 1) % 4;

  Move? aiChooseMove() {
    Move? best; 
    int score = -999999;
    for (var c in current.hand) {
      for (var mv in validMoves(c)) {
        int s = 0;
        if (mv.type == MoveType.exitBase) {
          s = 500;
        } else if (mv.type == MoveType.advance) {
          s = current.pawns[mv.pawnIndex].progress + c.forwardSteps;
          if (current.pawns[mv.pawnIndex].progress + c.forwardSteps == 57) s += 10000;
          if (c.forwardSteps < 0) s -= 200;
        } else if (mv.type == MoveType.swap) { // إصلاح ثاني هنا
          final otherPlayer = mv.other!;
          s = otherPlayer.pawns[mv.otherPawnIndex!].progress - current.pawns[mv.pawnIndex].progress + 100;
        }
        s += r.nextInt(40);
        if (s > score) { 
          score = s; 
          best = mv; 
        }
      }
    }
    return best;
  }
}
