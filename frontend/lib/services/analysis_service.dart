// Ported analysis algorithms from server/services/analysis.ts
import 'dart:math';

class AudioFeatures {
  final double energy;
  final double danceability;
  final double valence;
  final double acousticness;
  final double instrumentalness;
  final double tempo;
  final double liveness;
  final double speechiness;

  AudioFeatures({
    required this.energy,
    required this.danceability,
    required this.valence,
    required this.acousticness,
    required this.instrumentalness,
    required this.tempo,
    required this.liveness,
    required this.speechiness,
  });
}

class AnalysisService {
  // 1. Calculate Playlist Health Score
  static Map<String, dynamic> calculateHealth(
    List<AudioFeatures> features,
    int totalTracks,
    int uniqueGenres,
  ) {
    if (features.isEmpty) {
      return {'score': 0, 'status': 'Unknown'};
    }

    // Metric 1: Consistency (Standard Deviation of Energy)
    final energyMean = features.map((f) => f.energy).reduce((a, b) => a + b) / features.length;
    final energyVariance = features
        .map((f) => (f.energy - energyMean) * (f.energy - energyMean))
        .reduce((a, b) => a + b) / features.length;
    final energyStdDev = energyVariance > 0 ? energyVariance : 0.0;
    
    // Lower deviation is better for flow, but too low is boring. Ideal is around 0.1-0.2
    final flowScore = energyStdDev < 0.2 
        ? 100.0 
        : (100.0 - ((energyStdDev - 0.2) * 200)).clamp(0.0, 100.0);

    // Metric 2: Variety (Genre/Track Ratio)
    final varietyScore = (uniqueGenres / totalTracks * 500).clamp(0.0, 100.0);

    // Metric 3: Quality (Engagement - using Danceability as proxy)
    final engagementScore = features
        .map((f) => f.danceability)
        .reduce((a, b) => a + b) / features.length * 100;

    final totalScore = ((flowScore * 0.4) + (varietyScore * 0.3) + (engagementScore * 0.3)).round();

    String status = 'Needs Work';
    if (totalScore >= 90) {
      status = 'Exceptional';
    } else if (totalScore >= 75) {
      status = 'Great';
    } else if (totalScore >= 60) {
      status = 'Good';
    } else if (totalScore >= 40) {
      status = 'Average';
    }

    return {'score': totalScore, 'status': status};
  }

  // 2. Determine Personality
  static Map<String, String> determinePersonality(
    List<AudioFeatures> features,
    List<String> genres,
  ) {
    if (features.isEmpty) {
      return {
        'type': 'Unknown',
        'description': 'Not enough data to determine personality',
      };
    }

    double avg(double Function(AudioFeatures) selector) {
      return features.map(selector).reduce((a, b) => a + b) / features.length;
    }
    
    final energy = avg((f) => f.energy);
    final valence = avg((f) => f.valence);
    final dance = avg((f) => f.danceability);
    final acoustic = avg((f) => f.acousticness);
    final instrumental = avg((f) => f.instrumentalness);

    // Check for "Experimental" (High Instrumental, Low Valence/Dance)
    if (instrumental > 0.3 || (energy > 0.8 && dance < 0.4)) {
      return {
        'type': 'The Experimentalist',
        'description': 'You explore the outer edges of sound. Conventions don\'t bind you; you seek textures and atmospheres over catchy hooks.',
      };
    }

    // Check for "Mood-Driven" (High Acoustic, Extreme Valence)
    if (acoustic > 0.5 || valence < 0.3 || valence > 0.8) {
      return {
        'type': 'Mood-Driven',
        'description': 'Music is an emotional amplifier for you. You curate soundscapes that perfectly match or alter your internal state.',
      };
    }

    // Check for "Eclectic" (High Genre Count - using feature variance)
    if (energy > 0.4 && acoustic > 0.3) {
      return {
        'type': 'The Eclectic',
        'description': 'Why choose one lane? You cruise through genres with ease, finding the common thread between folk, pop, and rock.',
      };
    }

    // Default: "Trend-Aware"
    return {
      'type': 'Trend-Aware',
      'description': 'You have your finger on the pulse. Your playlist keeps the energy high and the vibes current.',
    };
  }

  // 3. Subgenre Classification
  static List<Map<String, dynamic>> classifySubgenres(Map<String, int> genres) {
    final sorted = genres.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Skip top 3 (likely broad genres) and take next 6
    return sorted.skip(3).take(6).map((entry) => {
      'name': entry.key,
      'value': entry.value,
    }).toList();
  }

  // 4. Overall Rating
  static Map<String, dynamic> calculateRating(int healthScore, int trackCount) {
    double baseRating = healthScore / 20.0; // 0-5 scale
    
    // Penalize very short or very long playlists slightly
    if (trackCount < 10) baseRating *= 0.9;
    if (trackCount > 500) baseRating *= 0.95;

    final rating = (baseRating.clamp(1.0, 5.0) * 10).round() / 10;
    
    String description = 'Solid collection.';
    if (rating >= 4.8) {
      description = 'Masterpiece curation.';
    } else if (rating >= 4.5) {
      description = 'Highly curated selection.';
    } else if (rating >= 4.0) {
      description = 'Well balanced mix.';
    } else if (rating >= 3.0) {
      description = 'Good potential.';
    }

    return {'rating': rating, 'description': description};
  }

  // 5. Enhanced Battle Compatibility with Weighted Similarity
  static int calculateCompatibility(
    List<AudioFeatures> f1,
    List<AudioFeatures> f2,
  ) {
    if (f1.isEmpty || f2.isEmpty) return 0;

    final avg1 = _getAverageFeatures(f1);
    final avg2 = _getAverageFeatures(f2);

    // Weighted cosine similarity
    final weights = {
      'energy': 0.25,
      'danceability': 0.20,
      'valence': 0.20,
      'acousticness': 0.15,
      'instrumentalness': 0.20,
    };

    double weightedDotProduct = 0;
    double weightSum1 = 0;
    double weightSum2 = 0;

    weights.forEach((feature, weight) {
      final val1 = _getFeatureValue(avg1, feature);
      final val2 = _getFeatureValue(avg2, feature);

      weightedDotProduct += (val1 * val2) * weight;
      weightSum1 += (val1 * val1) * weight;
      weightSum2 += (val2 * val2) * weight;
    });

    final mag1 = weightSum1 > 0 ? weightSum1 : 0.0;
    final mag2 = weightSum2 > 0 ? weightSum2 : 0.0;

    if (mag1 == 0 || mag2 == 0) return 0;

    final similarity = weightedDotProduct / (mag1 * mag2);

    // Apply sigmoid transformation
    final sigmoidSimilarity = 1 / (1 + exp(-5 * (similarity - 0.5)));

    return (sigmoidSimilarity * 100).round();
  }

  static Map<String, double> _getAverageFeatures(List<AudioFeatures> features) {
    if (features.isEmpty) {
      return {
        'energy': 0.0,
        'danceability': 0.0,
        'valence': 0.0,
        'acousticness': 0.0,
        'instrumentalness': 0.0,
      };
    }

    return {
      'energy': features.map((f) => f.energy).reduce((a, b) => a + b) / features.length,
      'danceability': features.map((f) => f.danceability).reduce((a, b) => a + b) / features.length,
      'valence': features.map((f) => f.valence).reduce((a, b) => a + b) / features.length,
      'acousticness': features.map((f) => f.acousticness).reduce((a, b) => a + b) / features.length,
      'instrumentalness': features.map((f) => f.instrumentalness).reduce((a, b) => a + b) / features.length,
    };
  }

  static double _getFeatureValue(Map<String, double> avg, String feature) {
    return avg[feature] ?? 0.0;
  }
}

