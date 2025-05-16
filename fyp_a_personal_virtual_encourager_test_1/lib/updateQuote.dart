import 'package:cloud_firestore/cloud_firestore.dart';

class Quote {
  final String id;
  final String text;
  final String author;
  final String tag;
  final String personality;

  Quote({required this.id, required this.text, required this.author, required this.tag, required this.personality});

  Map<String, dynamic> toFirestore() { 
    return {
      'quoteText': text,
      'author': author,
      'tag': tag,
      'personality': personality
    };
  }
}

Future<void> populateFirestoreWithQuotes() async {
  try {
    CollectionReference quotesCollection = FirebaseFirestore.instance.collection('quoteDB');

    List<Quote> quotes = [
      Quote(id: '', text: "Strive not to be a success, but rather to be of value.", author: "Albert Einstein", tag:"Success", personality:"Openness to Experience"),
Quote(id: '', text: "The only way to do great work is to love what you do.", author: "Steve Jobs", tag:"Work", personality:"Conscientiousness"),
Quote(id: '', text: "The mind is everything. What you think you become.", author: "Buddha", tag:"Mindfulness", personality:"Emotional Stability"),
Quote(id: '', text: "Life is what happens when you're busy making other plans.", author: "John Lennon", tag:"Life", personality:"Openness to Experience"),
Quote(id: '', text: "Be the change that you wish to see in the world.", author: "Mahatma Gandhi", tag:"Change and Growth", personality:"Agreeableness"),
Quote(id: '', text: "Spread love everywhere you go. Let no one ever come to you without leaving happier.", author: "Mother Teresa", tag:"Love", personality:"Agreeableness"),
Quote(id: '', text: "It is during our darkest moments that we must focus to see the light.", author: "Aristotle", tag:"Overcoming Obstacles", personality:"Emotional Stability"),
Quote(id: '', text: "Not all of us can do great things. But we can do small things with great love.", author: "Mother Teresa", tag:"Love", personality:"Agreeableness"),
Quote(id: '', text: "The best and most beautiful things in the world cannot be seen or even touched - they must be felt with the heart.", author: "Helen Keller", tag:"Love", personality:"Openness to Experience"),
Quote(id: '', text: "Believe you can and you're halfway there.", author: "Theodore Roosevelt", tag:"Self-Confidence", personality:"Conscientiousness"),
Quote(id: '', text: "The future belongs to those who believe in the beauty of their dreams.", author: "Eleanor Roosevelt", tag:"Dreams and Goals", personality:"Openness to Experience"),
Quote(id: '', text: "You must be the change you wish to see in the world.", author: "Mahatma Gandhi", tag:"Change and Growth", personality:"Agreeableness"),
Quote(id: '', text: "To be yourself in a world that is constantly trying to make you something else is the greatest accomplishment.", author: "Ralph Waldo Emerson", tag:"Self-Confidence", personality:"Openness to Experience"),
Quote(id: '', text: "Darkness cannot drive out darkness: only light can do that. Hate cannot drive out hate: only love can do that.", author: "Martin Luther King Jr.", tag:"Love", personality:"Agreeableness"),
Quote(id: '', text: "The only limit to our realization of tomorrow will be our doubts of today.", author: "Franklin D. Roosevelt", tag:"Self-Confidence", personality:"Emotional Stability"),
Quote(id: '', text: "It does not matter how slowly you go as long as you do not stop.", author: "Confucius", tag:"Perseverance", personality:"Conscientiousness"),
Quote(id: '', text: "Well done is better than well said.", author: "Benjamin Franklin", tag:"Work", personality:"Conscientiousness"),
Quote(id: '', text: "The journey of a thousand miles begins with a single step.", author: "Lao Tzu", tag:"Perseverance", personality:"Conscientiousness"),
Quote(id: '', text: "Happiness is not something ready made. It comes from your own actions.", author: "Dalai Lama", tag:"Happiness", personality:"Emotional Stability"),
Quote(id: '', text: "The greatest glory in living lies not in never falling, but in rising every time we fall.", author: "Nelson Mandela", tag:"Overcoming Obstacles", personality:"Emotional Stability"),
Quote(id: '', text: "What we think, we become.", author: "Buddha", tag:"Mindfulness", personality:"Emotional Stability"),
Quote(id: '', text: "The best way to predict your future is to create it.", author: "Peter Drucker", tag:"Dreams and Goals", personality:"Conscientiousness"),
Quote(id: '', text: "You miss 100% of the shots you don't take.", author: "Wayne Gretzky", tag:"Success", personality:"Extraversion"),
Quote(id: '', text: "The greatest wealth is health.", author: "Virgil", tag:"Health and Fitness", personality:"Conscientiousness"),
Quote(id: '', text: "If you can dream it, you can achieve it.", author: "Zig Ziglar", tag:"Dreams and Goals", personality:"Extraversion"),
Quote(id: '', text: "The only person you are destined to become is the person you decide to be.", author: "Ralph Waldo Emerson", tag:"Self-Confidence", personality:"Openness to Experience"),
Quote(id: '', text: "Our greatest weakness lies in giving up. The most certain way to succeed is always to try just one more time.", author: "Thomas A. Edison", tag:"Perseverance", personality:"Conscientiousness"),
Quote(id: '', text: "Be kind, for everyone you meet is fighting a hard battle.", author: "Plato", tag:"Friendship", personality:"Agreeableness"),
Quote(id: '', text: "In three words I can sum up everything I've learned about life: it goes on.", author: "Robert Frost", tag:"Life", personality:"Emotional Stability"),
Quote(id: '', text: "The purpose of our lives is to be happy.", author: "Dalai Lama", tag:"Happiness", personality:"Agreeableness"),
Quote(id: '', text: "Do not go where the path may lead, go instead where there is no path and leave a trail.", author: "Ralph Waldo Emerson", tag:"Leadership", personality:"Openness to Experience"),
Quote(id: '', text: "The best preparation for tomorrow is doing your best today.", author: "H. Jackson Brown Jr.", tag:"Time Management", personality:"Conscientiousness"),
Quote(id: '', text: "Happiness is when what you think, what you say, and what you do are in harmony.", author: "Mahatma Gandhi", tag:"Happiness", personality:"Agreeableness"),
Quote(id: '', text: "It's not whether you get knocked down, it's whether you get up.", author: "Vince Lombardi", tag:"Perseverance", personality:"Conscientiousness"),
Quote(id: '', text: "Challenges are what make life interesting. Overcoming them is what makes life meaningful.", author: "Joshua Marine", tag:"Overcoming Obstacles", personality:"Emotional Stability"),
Quote(id: '', text: "The secret of getting ahead is getting started.", author: "Mark Twain", tag:"Time Management", personality:"Conscientiousness"),
Quote(id: '', text: "You are never too old to set another goal or to dream a new dream.", author: "C.S. Lewis", tag:"Dreams and Goals", personality:"Openness to Experience"),
Quote(id: '', text: "To handle yourself, use your head; to handle others, use your heart.", author: "Eleanor Roosevelt", tag:"Leadership", personality:"Agreeableness"),
Quote(id: '', text: "The two most important days in your life are the day you are born and the day you find out why.", author: "Mark Twain", tag:"Life", personality:"Openness to Experience"),
Quote(id: '', text: "You can't use up creativity. The more you use, the more you have.", author: "Maya Angelou", tag:"Creativity", personality:"Openness to Experience"),
Quote(id: '', text: "Every strike brings me closer to the next home run.", author: "Babe Ruth", tag:"Failure", personality:"Conscientiousness"),
Quote(id: '', text: "Don't watch the clock; do what it does. Keep going.", author: "Sam Levenson", tag:"Time Management", personality:"Conscientiousness"),
Quote(id: '', text: "Your time is limited, don't waste it living someone else's life.", author: "Steve Jobs", tag:"Time Management", personality:"Openness to Experience"),
Quote(id: '', text: "The question isn't who is going to let me; it's who is going to stop me?", author: "Ayn Rand", tag:"Self-Confidence", personality:"Extraversion"),
Quote(id: '', text: "The greatest discovery of all time is that a person can change his future by merely changing his attitude.", author: "Oprah Winfrey", tag:"Change and Growth", personality:"Emotional Stability"),
Quote(id: '', text: "I can't change the direction of the wind, but I can adjust my sails to always reach my destination.", author: "Jimmy Dean", tag:"Perseverance", personality:"Emotional Stability"),
Quote(id: '', text: "It is better to fail in originality than to succeed in imitation.", author: "Herman Melville", tag:"Creativity", personality:"Openness to Experience"),
Quote(id: '', text: "We must let go of the life we planned, so as to accept the one that is waiting for us.", author: "Joseph Campbell", tag:"Change and Growth", personality:"Openness to Experience"),
Quote(id: '', text: "Success is not final, failure is not fatal: it is the courage to continue that counts.", author: "Winston Churchill", tag:"Perseverance", personality:"Emotional Stability"),
Quote(id: '', text: "Be thankful for what you have; you'll end up having more. If you concentrate on what you don't have, you will never, ever have enough.", author: "Oprah Winfrey", tag:"Gratitude", personality:"Agreeableness"),
Quote(id: '', text: "The most common way people give up their power is by thinking they don't have any.", author: "Alice Walker", tag:"Self-Confidence", personality:"Emotional Stability"),
Quote(id: '', text: "Yesterday is history, tomorrow is a mystery, today is a gift of God, which is why we call it the present.", author: "Bill Keane", tag:"Life", personality:"Mindfulness"),
Quote(id: '', text: "If opportunity doesn't knock, build a door.", author: "Milton Berle", tag:"Success", personality:"Conscientiousness"),
Quote(id: '', text: "Every accomplishment starts with the decision to try.", author: "Gail Devers", tag:"Perseverance", personality:"Conscientiousness"),
Quote(id: '', text: "You have power over your mind - not outside events. Realize this, and you will find strength.", author: "Marcus Aurelius", tag:"Mindfulness", personality:"Emotional Stability"),
Quote(id: '', text: "When you have a dream, you've got to grab it and never let go.", author: "Carol Burnett", tag:"Dreams and Goals", personality:"Extraversion"),
Quote(id: '', text: "You can't build a reputation on what you are going to do.", author: "Henry Ford", tag:"Work", personality:"Conscientiousness"),
Quote(id: '', text: "The greatest use of life is to spend it for something that will outlast it.", author: "William James", tag:"Life", personality:"Openness to Experience"),
Quote(id: '', text: "It's not what you look at that matters, it's what you see.", author: "Henry David Thoreau", tag:"Mindfulness", personality:"Openness to Experience"),
Quote(id: '', text: "The secret to happiness is not in doing what one likes, but in liking what one does.", author: "James M. Barrie", tag:"Happiness", personality:"Emotional Stability"),
Quote(id: '', text: "Keep your face always toward the sunshine, and shadows will fall behind you.", author: "Walt Whitman", tag:"Happiness", personality:"Extraversion"),
Quote(id: '', text: "The art of life lies in a constant readjustment to our surroundings.", author: "Kakuzo Okakura", tag:"Change and Growth", personality:"Openness to Experience"),
Quote(id: '', text: "A friend is one that knows you as you are, understands where you have been, accepts what you have become, and still, gently allows you to grow.", author: "William Shakespeare", tag:"Friendship", personality:"Agreeableness"),
Quote(id: '', text: "The best revenge is massive success.", author: "Frank Sinatra", tag:"Success", personality:"Extraversion"),
Quote(id: '', text: "Great minds discuss ideas; average minds discuss events; small minds discuss people.", author: "Eleanor Roosevelt", tag:"Leadership", personality:"Openness to Experience"),
Quote(id: '', text: "You will face many defeats in life, but never let yourself be defeated.", author: "Maya Angelou", tag:"Perseverance", personality:"Emotional Stability"),
Quote(id: '', text: "The only thing that stands between you and your dream is the will to try and the belief that it is actually possible.", author: "Joel Brown", tag:"Dreams and Goals", personality:"Self-Confidence"),
Quote(id: '', text: "The difference between ordinary and extraordinary is that little extra.", author: "Jimmy Johnson", tag:"Success", personality:"Conscientiousness"),
Quote(id: '', text: "Your work is going to fill a large part of your life, and the only way to be truly satisfied is to do what you believe is great work.", author: "Steve Jobs", tag:"Work", personality:"Conscientiousness"),
Quote(id: '', text: "It is not in the stars to hold our destiny but in ourselves.", author: "William Shakespeare", tag:"Self-Confidence", personality:"Emotional Stability"),
Quote(id: '', text: "The greatest glory is not in never falling, but in rising every time you fall.", author: "Confucius", tag:"Overcoming Obstacles", personality:"Emotional Stability"),
Quote(id: '', text: "Don't cry because it's over, smile because it happened.", author: "Dr. Seuss", tag:"Life", personality:"Agreeableness"),
Quote(id: '', text: "Do what you can, with what you have, where you are.", author: "Theodore Roosevelt", tag:"Perseverance", personality:"Conscientiousness"),
Quote(id: '', text: "Let us always meet each other with smile, for the smile is the beginning of love.", author: "Mother Teresa", tag:"Love", personality:"Agreeableness"),
Quote(id: '', text: "Keep your dreams alive. Understand to achieve anything requires faith and belief in yourself, vision, hard work, determination, and dedication. Remember all things are possible for those who believe.", author: "Gail Devers", tag:"Dreams and Goals", personality:"Conscientiousness"),
Quote(id: '', text: "The best time to plant a tree was 20 years ago. The second best time is now.", author: "Chinese Proverb", tag:"Time Management", personality:"Conscientiousness"),
Quote(id: '', text: "If you are not willing to risk the unusual, you will have to settle for the ordinary.", author: "Jim Rohn", tag:"Courage", personality:"Openness to Experience"),
Quote(id: '', text: "Believe in yourself and all that you are. Know that there is something inside you that is greater than any obstacle.", author: "Christian D. Larson", tag:"Self-Confidence", personality:"Emotional Stability"),
Quote(id: '', text: "The way to get started is to quit talking and begin doing.", author: "Walt Disney", tag:"Time Management", personality:"Conscientiousness")
    ];

    for (Quote quote in quotes) {
      await quotesCollection.add(quote.toFirestore()); 
      print("Added quote: ${quote.text}");
    }

    print("Quotes added successfully!");
  } catch (e) {
    print("Error populating Firestore: $e");
  }
}