/// Clean LaTeX/Markdown-like math to readable Unicode text for display.
String cleanMathForDisplay(String text) {
  var cleaned = text;

  // 1) Remove LaTeX math delimiters but keep content (use raw regex strings)
  cleaned = cleaned.replaceAllMapped(
    RegExp(r'\\\((.*?)\\\)'),
    (m) => m.group(1) ?? '',
  );
  cleaned = cleaned.replaceAllMapped(
    RegExp(r'\\\[(.*?)\\\]'),
    (m) => m.group(1) ?? '',
  );
  cleaned = cleaned.replaceAllMapped(
    RegExp(r'\$\$(.*?)\$\$'),
    (m) => m.group(1) ?? '',
  );
  cleaned = cleaned.replaceAllMapped(
    RegExp(r'\$(.*?)\$'),
    (m) => m.group(1) ?? '',
  );

  // 2) Simple LaTeX command replacements (regex so single backslash variants are matched)
  const repl = <String, String>{
    r'\\times': '×',
    r'\\cdot': '·',
    r'\\ast': '∗',
    r'\\div': '÷',
    r'\\pm': '±',
    r'\\le': '≤',
    r'\\ge': '≥',
    r'\\ne': '≠',
    r'\\approx': '≈',
    r'\\pi': 'π',
    // Greek letters commonly used
    r'\\lambda': 'λ',
    r'\\gamma': 'γ',
    r'\\delta': 'δ',
    r'\\epsilon': 'ε',
    r'\\mu': 'μ',
    r'\\sigma': 'σ',
    r'\\rho': 'ρ',
    r'\\phi': 'φ',
    r'\\varphi': 'φ',
    r'\\omega': 'ω',
    r'\\Gamma': 'Γ',
    r'\\Delta': 'Δ',
    r'\\Sigma': 'Σ',
    r'\\Omega': 'Ω',
    r'\\alpha': 'α',
    r'\\beta': 'β',
    r'\\theta': 'θ',
    r'\\sqrt': '√',
    // Functions
    r'\\log': 'log',
    r'\\ln': 'ln',
    r'\\sin': 'sin',
    r'\\cos': 'cos',
    r'\\tan': 'tan',
  };
  repl.forEach((k, v) => cleaned = cleaned.replaceAll(RegExp(k), v));

  // 3) Fractions (common Unicode) and generic \frac{a}{b}
  const fractions = {
    '1/2': '½',
    '1/3': '⅓',
    '2/3': '⅔',
    '1/4': '¼',
    '3/4': '¾',
    '1/5': '⅕',
    '2/5': '⅖',
    '3/5': '⅗',
    '4/5': '⅘',
    '1/6': '⅙',
    '5/6': '⅚',
    '1/8': '⅛',
    '3/8': '⅜',
    '5/8': '⅝',
    '7/8': '⅞',
  };
  fractions.forEach((k, v) => cleaned = cleaned.replaceAll(k, v));
  cleaned = cleaned.replaceAllMapped(
    RegExp(r'\\frac\s*\{([^}]*)\}\s*\{([^}]*)\}'),
    (m) {
      final n = (m.group(1) ?? '').trim();
      final d = (m.group(2) ?? '').trim();
      final key = '$n/$d';
      return fractions[key] ?? '($n)/($d)';
    },
  );

  // 4) Square roots: \sqrt{...} and nth roots \sqrt[n]{...}
  cleaned = cleaned.replaceAllMapped(
    RegExp(r'\\sqrt\s*\[([^\]]*)\]\s*\{([^}]*)\}'),
    (m) {
      final n = (m.group(1) ?? '').trim();
      final c = (m.group(2) ?? '').trim();
      final sup = _toSuperscript(n);
      final body = c.contains(RegExp(r'[+\-*/]')) ? '($c)' : c;
      return '$sup√$body';
    },
  );
  cleaned = cleaned.replaceAllMapped(RegExp(r'\\sqrt\s*\{([^}]*)\}'), (m) {
    final c = (m.group(1) ?? '').trim();
    return c.contains(RegExp(r'[+\-*/]')) ? '√($c)' : '√$c';
  });

  // 5) Caret exponents: a^2, a^{10}
  // Include Greek block \u0370-\u03FF so letters like λ, π, θ work.
  cleaned = cleaned.replaceAllMapped(
    RegExp(r'([A-Za-z0-9\)\u0370-\u03FF])\^\{([^}]*)\}'),
    (m) {
      return '${m.group(1)}${_toSuperscript(m.group(2) ?? '')}';
    },
  );
  cleaned = cleaned.replaceAllMapped(
    RegExp(r'([A-Za-z0-9\)\u0370-\u03FF])\^(-?\d{1,3})'),
    (m) {
      return '${m.group(1)}${_toSuperscript(m.group(2) ?? '')}';
    },
  );

  // 6) Subscripts: a_1, a_{12}
  cleaned = cleaned.replaceAllMapped(
    RegExp(r'([A-Za-z\u0370-\u03FF])_\{(\d{1,4})\}'),
    (m) => '${m.group(1)}${_toSubscript(m.group(2) ?? '')}',
  );
  cleaned = cleaned.replaceAllMapped(
    RegExp(r'([A-Za-z\u0370-\u03FF])_(\d{1,4})'),
    (m) => '${m.group(1)}${_toSubscript(m.group(2) ?? '')}',
  );

  // 7) Improve multiplication display for numbers only: 2*3 -> 2×3
  cleaned = cleaned.replaceAllMapped(
    RegExp(r'(\d)\s*\*\s*(\d)'),
    (m) => '${m.group(1)}×${m.group(2)}',
  );

  // 8) Remove remaining LaTeX commands and stray backslashes (preserve newlines)
  cleaned = cleaned.replaceAll(RegExp(r'\\[a-zA-Z]+'), '');
  cleaned = cleaned.replaceAll(RegExp(r'\\'), '');
  cleaned = cleaned.replaceAll('{', '').replaceAll('}', '');

  // 9) Add spacing around basic operators for readability, but avoid touching parentheses boundaries
  // Only space when both sides are letters/digits/greek to keep forms like (1-λ) or a*(-b)
  cleaned = cleaned.replaceAllMapped(
    RegExp(r'([A-Za-z0-9\u0370-\u03FF])([+\-×÷=])([A-Za-z0-9\u0370-\u03FF])'),
    (m) => '${m.group(1)} ${m.group(2)} ${m.group(3)}',
  );

  // 10) Normalize whitespace (preserve newlines)
  cleaned = cleaned.replaceAll(RegExp(r'[ \t]+'), ' ');
  cleaned = cleaned.replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n');
  cleaned = cleaned.split('\n').map((l) => l.trimRight()).join('\n');

  return cleaned.trim();
}

String _toSuperscript(String s) {
  const map = {
    '0': '⁰',
    '1': '¹',
    '2': '²',
    '3': '³',
    '4': '⁴',
    '5': '⁵',
    '6': '⁶',
    '7': '⁷',
    '8': '⁸',
    '9': '⁹',
    '+': '⁺',
    '-': '⁻',
    '(': '⁽',
    ')': '⁾',
  };
  return s.split('').map((c) => map[c] ?? c).join('');
}

String _toSubscript(String s) {
  const map = {
    '0': '₀',
    '1': '₁',
    '2': '₂',
    '3': '₃',
    '4': '₄',
    '5': '₅',
    '6': '₆',
    '7': '₇',
    '8': '₈',
    '9': '₉',
    '+': '₊',
    '-': '₋',
    '(': '₍',
    ')': '₎',
  };
  return s.split('').map((c) => map[c] ?? c).join('');
}
