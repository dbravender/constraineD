import "package:constrained/constrained.dart";

class Card {
  final int id;
  final int value;
  final Suit suit;

  Card({required this.id, required this.value, required this.suit});

  @override
  operator ==(Object other) {
    if (other is! Card) {
      return false;
    }
    return other.id == id;
  }

  @override
  String toString() {
    return "<Card id=$id value=$value suit=$suit>";
  }
}

enum Suit {
  red,
  blue,
  yellow,
  pass,
}

List<Card> deck() {
  List<Card> deck = [];
  int id = 0;
  for (var suit in [Suit.blue, Suit.red, Suit.yellow]) {
    for (var value in [1, 2, 3, 4, 5, 6, 7, 8, 9]) {
      deck.add(Card(id: id++, value: value, suit: suit));
    }
  }
  // 3 pass cards
  deck.add(Card(id: id++, value: 0, suit: Suit.pass));
  deck.add(Card(id: id++, value: 0, suit: Suit.pass));
  deck.add(Card(id: id++, value: 0, suit: Suit.pass));
  deck.shuffle();
  return deck;
}

class HandsGivenVoids extends ListConstraint {
  HandsGivenVoids(List<int> indicies) : super(indicies);

  bool isSatisfied(Map assignment) {
    // Each card should be distinct
    Set d = Set.from(assignment.values);
    if (d.length < assignment.length) {
      return false;
    }

    // if all variables have been assigned, check if it adds up correctly
    if (assignment.length == variables.length) {
      return true;
    }

    // until we have all of the variables assigned, the assignment is valid
    return true;
  }
}

List<Card> cardsForVoids(
    int length, List<Card> allCards, Map<Suit, bool> voids) {
  if (voids.isEmpty) {
    return allCards;
  }
  return allCards.where((c) => !voids.containsKey(c.suit)).toList();
}

Map<int, List<Card>> getDomains(
    List<List<Card>> hands, List<Map<Suit, bool>> voids) {
  Map<int, List<Card>> domains = {};
  List<Card> allCards = [];
  int offset = 0;
  for (var hand in hands) {
    allCards.addAll(hand);
  }
  allCards.shuffle();
  hands.asMap().forEach((player, hand) {
    hand.forEach((element) {
      domains[offset] = cardsForVoids(hand.length, allCards, voids[player]);
      offset++;
    });
  });

  return domains;
}

List<List<Card>> possibleHand(
    List<List<Card>> currentHands, List<Map<Suit, bool>> voids) {
  Map<int, List<Card>> domains = getDomains(currentHands, voids);
  List<int> variables = domains.keys.toList();

  CSP csp = new CSP(variables, domains);

  csp.addListConstraint(new HandsGivenVoids(variables));

  var solution = backtrackingSearch(csp, {}, mrv: true);
  int offset = 0;
  List<List<Card>> newHands = [[], [], [], []];
  currentHands.asMap().forEach((player, hand) {
    for (var i = 0; i < hand.length; i++) {
      newHands[player].add(solution![offset]);
      offset++;
    }
  });

  return newHands;
}

void main() async {
  List<List<Card>> hands = [
    [
      Card(id: 0, value: 1, suit: Suit.red),
      Card(id: 1, value: 2, suit: Suit.red),
      Card(id: 2, value: 3, suit: Suit.red),
      Card(id: 3, value: 4, suit: Suit.red),
    ],
    [
      Card(id: 4, value: 1, suit: Suit.blue),
      Card(id: 5, value: 2, suit: Suit.blue),
      Card(id: 6, value: 3, suit: Suit.blue),
      Card(id: 7, value: 4, suit: Suit.blue),
    ],
    [
      Card(id: 8, value: 1, suit: Suit.yellow),
      Card(id: 9, value: 2, suit: Suit.yellow),
      Card(id: 10, value: 3, suit: Suit.yellow),
      Card(id: 11, value: 4, suit: Suit.yellow),
    ],
    [
      Card(id: 12, value: 1, suit: Suit.pass),
      Card(id: 13, value: 2, suit: Suit.pass),
      Card(id: 14, value: 3, suit: Suit.pass),
      Card(id: 15, value: 4, suit: Suit.pass),
    ],
  ];
  List<Map<Suit, bool>> voids = [
    {Suit.red: true},
    {},
    {Suit.blue: true, Suit.yellow: true},
    {}
  ];

  print(possibleHand(hands, voids));
}
