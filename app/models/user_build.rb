class UserBuild < ApplicationRecord
  belongs_to :user

  validates :bftBonus, presence: true,
                      numericality: { greater_than_or_equal_to: 0.0,
                                    less_than_or_equal_to: 600.0 }

  def calculate_multiplier
    # Si bftBonus est 0, retourner 1.0 (pas de bonus)
    return 1.0 if bftBonus.nil? || bftBonus.zero?

    # Points de référence connus (bftBonus => multiplicateur)
    known_points = {
      100.45 => 0.2905,
      148.81 => 0.3990,
      200.00 => 0.5700,
      276.12 => 0.7610,
      309.33 => 0.8450,
      400.00 => 1.0800,
      458.59 => 1.2050,
      600.00 => 1.5400
    }

    # Pour les valeurs en dehors de la plage connue
    return 0.2905 if bftBonus <= 100.45  # Minimum connu
    return 1.5400 if bftBonus >= 600.00  # Maximum connu

    # Trouver les points entre lesquels interpoler
    sorted_points = known_points.keys.sort
    lower_bonus = sorted_points.select { |x| x <= bftBonus }.last
    upper_bonus = sorted_points.select { |x| x > bftBonus }.first

    # Interpolation linéaire
    lower_mult = known_points[lower_bonus]
    upper_mult = known_points[upper_bonus]

    # Formule d'interpolation
    lower_mult + (bftBonus - lower_bonus) * (upper_mult - lower_mult) / (upper_bonus - lower_bonus)
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
