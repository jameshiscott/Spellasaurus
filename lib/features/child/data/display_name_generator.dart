import 'dart:math';

/// Categories for fun display-name generation.
class NameCategory {
  final String label;
  final String emoji;
  final List<String> adjectives;
  final List<String> nouns;

  const NameCategory({
    required this.label,
    required this.emoji,
    required this.adjectives,
    required this.nouns,
  });

  String generate([Random? rng]) {
    final r = rng ?? Random();
    final adj = adjectives[r.nextInt(adjectives.length)];
    final noun = nouns[r.nextInt(nouns.length)];
    return '$adj $noun';
  }
}

const nameCategories = [
  // ── Animal Chaos 🐵 ──────────────────────────────────────────────────
  NameCategory(
    label: 'Animal Chaos',
    emoji: '🐵',
    adjectives: [
      'Turbo', 'Mega', 'Sneaky', 'Wobbly', 'Captain', 'Fluffy',
      'Hyper', 'Zippy', 'Grumpy', 'Dizzy', 'Bouncy', 'Sparkly',
      'Mighty', 'Silly', 'Fancy', 'Cosmic', 'Jazzy', 'Ninja',
      'Cheeky', 'Squishy', 'Rowdy', 'Snappy', 'Chunky', 'Twirly',
      'Peppy', 'Clumsy', 'Bubbly', 'Pudgy', 'Slippery', 'Speedy',
      'Jumpy', 'Frantic', 'Dopey', 'Shabby', 'Scruffy', 'Sleepy',
      'Muddy', 'Fuzzy', 'Crazy', 'Electric', 'Floppy', 'Giggly',
      'Wiggly', 'Wacky', 'Howling', 'Prancing', 'Shuffling', 'Galloping',
      'Rumbling', 'Stomping',
    ],
    nouns: [
      'Penguin', 'Llama', 'Platypus', 'Wombat', 'Narwhal', 'Sloth',
      'Panda', 'Otter', 'Capybara', 'Flamingo', 'Gecko', 'Hamster',
      'Hedgehog', 'Toucan', 'Axolotl', 'Quokka', 'Lemur', 'Ferret',
      'Alpaca', 'Chinchilla', 'Armadillo', 'Chameleon', 'Peacock', 'Pelican',
      'Koala', 'Raccoon', 'Walrus', 'Badger', 'Meerkat', 'Porcupine',
      'Seahorse', 'Manatee', 'Jellyfish', 'Iguana', 'Parrot', 'Moose',
      'Chipmunk', 'Stingray', 'Starfish', 'Lobster', 'Beetle', 'Bison',
      'Ostrich', 'Vulture', 'Coyote', 'Goose', 'Donkey', 'Gopher',
      'Kiwi', 'Dugong',
    ],
  ),

  // ── Food Names 🍕 ────────────────────────────────────────────────────
  NameCategory(
    label: 'Food Names',
    emoji: '🍕',
    adjectives: [
      'Spicy', 'Crunchy', 'Bubbly', 'Toasty', 'Sizzling', 'Frozen',
      'Cheesy', 'Crispy', 'Zesty', 'Gooey', 'Fizzy', 'Tangy',
      'Saucy', 'Supreme', 'Golden', 'Double', 'Extra', 'Mega',
      'Sticky', 'Fluffy', 'Smoky', 'Loaded', 'Stuffed', 'Flaming',
      'Sugary', 'Buttery', 'Whipped', 'Melted', 'Glazed', 'Dipped',
      'Caramel', 'Pickled', 'Battered', 'Drizzled', 'Smothered', 'Sprinkled',
      'Popping', 'Steamy', 'Chunky', 'Twisted', 'Swirly', 'Jumbo',
      'Triple', 'Turbo', 'Atomic', 'Exploding', 'Legendary', 'Ultimate',
      'Cosmic', 'Volcanic',
    ],
    nouns: [
      'Taco', 'Waffle', 'Noodle', 'Muffin', 'Pretzel', 'Burrito',
      'Donut', 'Pancake', 'Nugget', 'Pickle', 'Cookie', 'Cupcake',
      'Popcorn', 'Dumpling', 'Churro', 'Nacho', 'Pizza', 'Biscuit',
      'Croissant', 'Sushi', 'Brownie', 'Falafel', 'Wonton', 'Crumpet',
      'Scone', 'Macaron', 'Strudel', 'Bagel', 'Calzone', 'Empanada',
      'Samosa', 'Crepe', 'Kebab', 'Corndog', 'Turnover', 'Eclair',
      'Fritter', 'Pierogi', 'Tamale', 'Brioche', 'Gyoza', 'Cannoli',
      'Cheddar', 'Pudding', 'Crouton', 'Tofu', 'Jalapeno', 'Lasagne',
      'Ravioli', 'Mochi',
    ],
  ),

  // ── Gamer Style 🎮 ──────────────────────────────────────────────────
  NameCategory(
    label: 'Gamer Style',
    emoji: '🎮',
    adjectives: [
      'Shadow', 'Pixel', 'Turbo', 'Glitch', 'Neon', 'Stealth',
      'Ultra', 'Hyper', 'Blaze', 'Storm', 'Frost', 'Thunder',
      'Cyber', 'Laser', 'Rocket', 'Vortex', 'Nitro', 'Atomic',
      'Phantom', 'Quantum', 'Nova', 'Inferno', 'Spectral', 'Omega',
      'Titanium', 'Chaos', 'Alpha', 'Primal', 'Savage', 'Elite',
      'Warp', 'Galactic', 'Plasma', 'Fusion', 'Overclocked', 'Infinite',
      'Zero', 'Binary', 'Hex', 'Vector', 'Rapid', 'Apex',
      'Supreme', 'Iron', 'Steel', 'Chrome', 'Dark', 'Blazing',
      'Fatal', 'Silent',
    ],
    nouns: [
      'Wolf', 'Phoenix', 'Dragon', 'Ninja', 'Knight', 'Titan',
      'Falcon', 'Cobra', 'Panther', 'Hawk', 'Raven', 'Viper',
      'Lynx', 'Fox', 'Raptor', 'Striker', 'Blaster', 'Racer',
      'Warden', 'Crusher', 'Hunter', 'Sniper', 'Guardian', 'Slayer',
      'Ranger', 'Sentinel', 'Sphinx', 'Griffin', 'Kraken', 'Golem',
      'Wraith', 'Samurai', 'Spartan', 'Viking', 'Gladiator', 'Trooper',
      'Maverick', 'Nomad', 'Outlaw', 'Bandit', 'Ace', 'Legend',
      'Reaper', 'Drifter', 'Runner', 'Bomber', 'Scorpion', 'Shark',
      'Mantis', 'Jaguar',
    ],
  ),

  // ── Hero Style but Ridiculous 🦸 ─────────────────────────────────────
  NameCategory(
    label: 'Hero Style',
    emoji: '🦸',
    adjectives: [
      'Captain', 'Doctor', 'Professor', 'The Incredible', 'Super',
      'The Amazing', 'Legendary', 'Ultra', 'Turbo', 'Mega',
      'The Mighty', 'Invincible', 'Unstoppable', 'Fearless',
      'The Great', 'Colossal', 'The Magnificent', 'Atomic',
      'Sergeant', 'Commander', 'Admiral', 'The Spectacular', 'Supreme',
      'The Unbeatable', 'Dynamic', 'The Notorious', 'Major', 'Inspector',
      'The Almighty', 'General', 'The Fabulous', 'Heroic', 'The Sensational',
      'The Dazzling', 'All-Powerful', 'The Glorious', 'The Majestic',
      'The Triumphant', 'The Astonishing', 'The Legendary', 'The Supreme',
      'The Radical', 'The Outrageous', 'The Phenomenal', 'The Unconquerable',
      'The Stupendous', 'The Formidable', 'The Extraordinary', 'The One and Only',
      'The Bewildering', 'The Fantastical',
    ],
    nouns: [
      'Sock', 'Spoon', 'Elbow', 'Banana', 'Teapot', 'Pillow',
      'Slipper', 'Moustache', 'Noodle Arm', 'Pancake', 'Bubble',
      'Wobble', 'Sneeze', 'Pudding', 'Doughnut', 'Sandwich',
      'Blanket', 'Crayon', 'Spatula', 'Marshmallow', 'Broccoli',
      'Flip Flop', 'Toilet Roll', 'Bumblebee', 'Custard Pie', 'Armpit',
      'Belly Button', 'Nostril', 'Eyelash', 'Toenail', 'Mushroom',
      'Cabbage', 'Spring Roll', 'Yoghurt', 'Toast', 'Turnip',
      'Jellybean', 'Cauliflower', 'Dishcloth', 'Bathrobe', 'Wardrobe',
      'Plunger', 'Teabag', 'Breadstick', 'Sprout', 'Crouton',
      'Napkin', 'Doorbell', 'Stapler', 'Curtain',
    ],
  ),

  // ── Silly Historical 🏛️ ──────────────────────────────────────────────
  NameCategory(
    label: 'Silly Historical',
    emoji: '🏛️',
    adjectives: [
      'Sir', 'Lord', 'Duchess', 'Baron', 'Count', 'King',
      'Queen', 'Emperor', 'Grand Duke', 'Sultan', 'Pharaoh',
      'Archduke', 'Czar', 'Shogun', 'Chief', 'Admiral',
      'General', 'Viking', 'Dame', 'Marquis', 'Viscount',
      'Prince', 'Princess', 'Cardinal', 'Chancellor', 'Viceroy',
      'Governor', 'Regent', 'Earl', 'Warlord', 'Chieftain',
      'Conqueror', 'High Priest', 'Oracle', 'Gladiator', 'Tribune',
      'Senator', 'Centurion', 'Magistrate', 'Squire', 'Knight',
      'Commodore', 'Marshal', 'Overlord', 'Monarch', 'Sovereign',
      'Empress', 'Tsar', 'Grand Vizier', 'Paladin', 'Noble',
    ],
    nouns: [
      'Wobblebottom', 'Noodlesworth', 'McFluffington',
      'Von Snickerdoodle', 'Bumblebee III', 'Wiggleton',
      'Fluffernutter', 'Gigglepants', 'Wobblesnack',
      'Ticklebottom', 'Snorkelface', 'Puddinghat',
      'Wafflebeard', 'Noodlehead', 'Biscuitsworth',
      'Crumblewick', 'Bumblefoot', 'Doodlebug',
      'Picklesworth', 'Bogglesworth', 'Squishington',
      'Wobblekins', 'Fiddlesticks', 'Crumpleton',
      'Muffinsworth', 'Snickerbottom', 'Waddlesworth',
      'Fumblewick', 'Gobbleston', 'Tumblebum',
      'Puddleworth', 'Bumblesnort', 'Noodlebrain',
      'Wigglesworth', 'Dribbleface', 'Sconeington',
      'Trouserbottom', 'Kerfuffle', 'Crumblesnatch',
      'McWobbleface', 'Butterfingers', 'Twiddlesworth',
      'Fumblethump', 'Jigglebottom', 'Snorkleberry',
      'Wibbleford', 'Crumplezone', 'Bumblethwaite',
      'Flapdoodle', 'Dandypants',
    ],
  ),

  // ── Random Goofiness 🤪 ──────────────────────────────────────────────
  NameCategory(
    label: 'Random Goofiness',
    emoji: '🤪',
    adjectives: [
      'Wiggly', 'Bonkers', 'Wacky', 'Loopy', 'Bizarre', 'Goofy',
      'Nutty', 'Kooky', 'Wonky', 'Zany', 'Funky', 'Quirky',
      'Barmy', 'Daft', 'Potty', 'Crackers', 'Mental', 'Batty',
      'Flappy', 'Jiggly', 'Squiggly', 'Noodly', 'Boingy', 'Springy',
      'Twisty', 'Floopy', 'Zappy', 'Blurpy', 'Splotchy', 'Wobbulous',
      'Googly', 'Zonky', 'Frazzled', 'Befuddled', 'Discombobulated', 'Bamboozled',
      'Flummoxed', 'Gobsmacked', 'Boggled', 'Squonky', 'Fizzly', 'Bumbly',
      'Topsy Turvy', 'Higgledy', 'Piggledy', 'Rumbly', 'Tumbly', 'Fumbling',
      'Bumbling', 'Stumbling',
    ],
    nouns: [
      'Banana', 'Trampoline', 'Doorknob', 'Spatula', 'Jellyfish',
      'Tornado', 'Blobfish', 'Unicycle', 'Catapult', 'Yodeller',
      'Wiggler', 'Boomerang', 'Spaghetti', 'Kazoo', 'Pinwheel',
      'Moonbeam', 'Sprocket', 'Custard', 'Zamboni', 'Accordion',
      'Dingleberry', 'Trombone', 'Windmill', 'Flamingo', 'Kaleidoscope',
      'Boondoggle', 'Cannonball', 'Whirlpool', 'Marshmallow', 'Rocketship',
      'Jackhammer', 'Pogo Stick', 'Roller Coaster', 'Whoopee Cushion', 'Confetti',
      'Firework', 'Snowglobe', 'Bubblewrap', 'Lollipop', 'Gumball',
      'Beeswax', 'Corkscrew', 'Hedgehog', 'Frisbee', 'Cartwheel',
      'Noodle', 'Waffle Iron', 'Tickle Monster', 'Jelly Tot', 'Bamboo',
    ],
  ),

  // ── Why Does This Even Exist 🤨 ───────────────────────────────────────
  NameCategory(
    label: 'Why Does This Exist',
    emoji: '🤨',
    adjectives: [
      'Slightly Damp', 'Confused', 'Invisible', 'Expired',
      'Haunted', 'Suspicious', 'Reluctant', 'Accidental',
      'Mysterious', 'Forgotten', 'Unnecessary', 'Unimpressed',
      'Bewildered', 'Startled', 'Overcooked', 'Lost',
      'Misplaced', 'Lukewarm', 'Deflated', 'Overdue',
      'Secondhand', 'Off-Brand', 'Semi-Transparent', 'Unfinished',
      'Questionable', 'Moderately Alarming', 'Mildly Concerning', 'Unplugged',
      'Discontinued', 'Refurbished', 'Upside Down', 'Inside Out', 'Half-Eaten',
      'Undercooked', 'Stale', 'Rusty', 'Dusty', 'Wrinkled',
      'Soggy', 'Crooked', 'Backwards', 'Tangled', 'Crumpled',
      'Wonky', 'Spare', 'Leftover', 'Unclaimed', 'Barely Legal',
      'Ambiguous', 'Inexplicable',
    ],
    nouns: [
      'Sandwich', 'Receipt', 'Sock Drawer', 'Tuesday',
      'Paperclip', 'Traffic Cone', 'Deckchair', 'Umbrella',
      'Doorstop', 'Lampshade', 'Shoelace', 'Button',
      'Mannequin', 'Tax Return', 'Speed Bump', 'Coat Hanger',
      'Puddle', 'Toast Rack', 'Warranty Card', 'Instruction Manual',
      'Rubber Duck', 'Parking Meter', 'Fax Machine', 'Dial Tone',
      'Screen Saver', 'Clipboard', 'Bookmark', 'Keyring',
      'Bread Tie', 'Fridge Magnet', 'Mouse Pad', 'Dust Bunny',
      'Lint Roller', 'Bath Plug', 'Pencil Sharpener', 'Cable Tie',
      'Post-It Note', 'Coaster', 'Thimble', 'Bottle Cap',
      'Safety Pin', 'Clothes Peg', 'Door Wedge', 'Sellotape',
      'Plug Socket', 'Price Tag', 'Bin Lid', 'Egg Cup',
      'Tea Towel', 'Flyswatter',
    ],
  ),
];
