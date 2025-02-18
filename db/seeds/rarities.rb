rarities = [
  { name: "Common", color: "#858F9B" },        # Gris
  { name: "Uncommon", color: "#1CBF6A" },      # Vert
  { name: "Rare", color: "#159CFD" },          # Bleu
  { name: "Epic", color: "#A369FF" },          # Violet
  { name: "Legendary", color: "#E67E22" },     # Orange
  { name: "Mythic", color: "#FFD32A" },        # Magenta
  { name: "Exalted", color: "#EF5777" },       # Jaune
  { name: "Exotic", color: "#BE2EDD" },        # Rose vif
  { name: "Transcendent", color: "#FF3838" },  # Cyan
  { name: "Unique", color: "#F368E0" }         # Blanc
]

rarities.each do |rarity|
  Rarity.find_or_create_by(name: rarity[:name]) do |r|
      r.color = rarity[:color]
  end
end
