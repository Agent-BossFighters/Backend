class UserBuild < ApplicationRecord
  belongs_to :user

  validates :bftBonus, presence: true,
                      numericality: { greater_than_or_equal_to: 0.0,
                                    less_than_or_equal_to: 3000.0 }

  def calculate_multiplier
    # Si bftBonus est 0, retourner 1.0 (pas de bonus)
    return 1.0 if bftBonus.nil? || bftBonus.zero?

    # bftBonus est le multiplicateur X (entre 0 et 600)
    # On calcule le pourcentage Y avec la formule : Y = 4.046E-7 * X^2 + 0.03236 * X + 6.409
    x = bftBonus
    percentage = 4.046e-7 * x * x + 0.03236 * x + 6.409

    # Le résultat est déjà un pourcentage, pas besoin de conversion
    percentage.round(4)
  end

  private

  def calculate_polynomial
    # Équation polynomiale de degré 7
    x = bftBonus
    (
      3.778e-25 * x**7 -
      2.64e-20 * x**6 +
      7.548e-16 * x**5 -
      1.141e-11 * x**4 +
      9.811e-8 * x**3 -
      0.000477 * x**2 +
      1.242 * x -
      1215.105
    ) * 0.994
  end

  def calculate_interpolation
    # Points de référence connus
    known_points = {
      100.45 => 29.05,
      148.81 => 39.90,
      200.00 => 57.00,
      276.12 => 76.10,
      309.33 => 84.50,
      400.00 => 108.00,
      458.59 => 120.50,
      600.00 => 154.00
    }

    # Trouver les points de référence les plus proches
    sorted_points = known_points.keys.sort
    return known_points[sorted_points.first] if bftBonus <= sorted_points.first
    return known_points[sorted_points.last] if bftBonus >= sorted_points.last

    # Trouver les points entre lesquels interpoler
    lower_y = sorted_points.select { |y| y <= bftBonus }.last
    upper_y = sorted_points.select { |y| y > bftBonus }.first

    # Interpolation linéaire
    lower_x = known_points[lower_y]
    upper_x = known_points[upper_y]

    # Formule d'interpolation : x = x1 + (y - y1) * (x2 - x1) / (y2 - y1)
    lower_x + (bftBonus - lower_y) * (upper_x - lower_x) / (upper_y - lower_y)
  end
end
