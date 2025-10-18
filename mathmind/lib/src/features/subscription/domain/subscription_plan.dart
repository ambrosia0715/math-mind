enum SubscriptionTier { free, basic, premium }

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.tier,
    required this.title,
    required this.description,
    required this.benefits,
  });

  final SubscriptionTier tier;
  final String title;
  final String description;
  final List<String> benefits;
}
