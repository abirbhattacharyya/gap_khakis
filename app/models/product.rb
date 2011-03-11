class Product < ActiveRecord::Base
  belongs_to :user
  has_many :offers

  validates_uniqueness_of :style_description, :scope => [:user_id, :color_description]

  def new_price_points
    if(self.ticketed_retail == 49.5)
      PromotionCode::PRICE_CODES_50
    else
      PromotionCode::PRICE_CODES_60
    end
  end

  def color
    self.color_description.gsub(/\d+/, '').strip
  end

  def target_price
    (self.ticketed_retail == 49.5) ? 30 : 35
  end

  def min_price
    (self.ticketed_retail == 49.5) ? 15 : 18
  end

  def images
    Product.all(:conditions => ["style_description = ? and image_url <> ? ", self.style_description, self.image_url])
  end

  def description
    if self.style_description.strip.eql? "CLASSIC STRAIGHT KHAKI"
      ["Fit for any occasion, you'll turn to the classic khaki again and again.",
        "
          <p><b>overview</b></p><ul>
          <li style='list-style: disc inside'>High-quality wrinkle-resistant and fade-proof cotton khaki pants.</li>
          <li style='list-style: disc inside'>Sits just below the waist.</li>
          <li style='list-style: disc inside'>Straight through the leg.</li>
          <li style='list-style: disc inside'>Straight leg opening.<br />
          <li style='list-style: disc inside'>Flat front, button closure, zip fly.</li>
          <li style='list-style: disc inside'>On-seam pockets, back button-welt pockets.</li></ul><br />

          <p><b>fabric & care</b></p><ul>
          <li style='list-style: disc inside'>100% Cotton.</li>
          <li style='list-style: disc inside'>Machine wash.</li>
          <li style='list-style: disc inside'>Imported.</li></ul>
        "
      ]
    elsif self.style_description.strip.eql? "CLASSIC RELAXED KHAKI"
      ["Fit for any occasion, you'll turn to the classic khaki again and again.",
        "
          <p><b>overview</b></p><ul>
          <li style='list-style: disc inside'>Soft, wrinkle-resistant and fade-proof cotton khaki pants.</li>
          <li style='list-style: disc inside'>Sits just below the waist.</li>
          <li style='list-style: disc inside'>Full through the leg.</li>
          <li style='list-style: disc inside'>Straight leg opening.</li>
          <li style='list-style: disc inside'>Flat front, button closure, zip fly.</li>
          <li style='list-style: disc inside'>On-seam pockets, back button-welt pockets.</li></ul><br />

          <p><b>fabric & care</b></p><ul>
          <li style='list-style: disc inside'>100% Cotton.</li>
          <li style='list-style: disc inside'>Machine wash.</li>
          <li style='list-style: disc inside'>Imported.</li></ul>
        "
      ]
    elsif self.style_description.strip.eql? "TAILORED STRAIGHT KHAKI"
      ["Our dressiest: designed with a creased leg, and wrinkle-resistant twill.",
        "
          <p><b>overview</b></p><ul>
          <li style='list-style: disc inside'>High-quality wrinkle-resistant and fade-proof cotton khaki pants.</li>
          <li style='list-style: disc inside'>Sits just below the waist.</li>
          <li style='list-style: disc inside'>Straight through the leg.</li>
          <li style='list-style: disc inside'>Straight leg opening.</li>
          <li style='list-style: disc inside'>Flat front, hook & bar closure, zip fly.</li>
          <li style='list-style: disc inside'>On-seam pockets, back button-welt pockets.</li></ul><br />

          <p><b>fabric & care</b></p><ul>
          <li style='list-style: disc inside'>100% Cotton.</li>
          <li style='list-style: disc inside'>Machine wash.</li>
          <li style='list-style: disc inside'>Imported.</li></ul>
        "
      ]
    elsif self.style_description.strip.eql? "TAILORED RELAXED KHAKI"
      ["Our dressiest: designed with a creased leg, and wrinkle-resistant twill.",
        "
          <p><b>overview</b></p><ul>
          <li style='list-style: disc inside'>High-quality wrinkle-resistant and fade-proof cotton khaki pants.</li>
          <li style='list-style: disc inside'>Sits just below the waist.</li>
          <li style='list-style: disc inside'>Full through the leg.</li>
          <li style='list-style: disc inside'>Straight leg opening.</li>
          <li style='list-style: disc inside'>Flat front, hook & bar closure, zip fly.</li>
          <li style='list-style: disc inside'>On-seam pockets, back button-welt pockets.</li></ul><br />

          <p><b>fabric & care</b></p><ul>
          <li style='list-style: disc inside'>100% Cotton.</li>
          <li style='list-style: disc inside'>Machine wash.</li>
          <li style='list-style: disc inside'>Imported.</li></ul>
        "
      ]
    elsif self.style_description.strip.eql? "VINTAGE KHAKI"
      ["Made of soft, prewashed cotton with a relaxed fit.",
        "
          <p><b>overview</b></p><ul>
          <li style='list-style: disc inside'>High-quality prewashed woven cotton khaki pants.</li>
          <li style='list-style: disc inside'>Sits just below the waist.</li>
          <li style='list-style: disc inside'>Easy through the leg.</li>
          <li style='list-style: disc inside'>Straight leg opening.</li>
          <li style='list-style: disc inside'>Button closure, zip fly.</li>
          <li style='list-style: disc inside'>On-seam pockets, mini-coin welt pocket, back button-welt pockets.</li></ul><br />

          <p><b>fabric & care</b></p><ul>
          <li style='list-style: disc inside'>100% Cotton.</li>
          <li style='list-style: disc inside'>Machine wash.</li>
          <li style='list-style: disc inside'>Imported.</li></ul>
        "
      ]
    elsif self.style_description.strip.eql? "TAILORED STRAIGHT MELANGE"
      ["Our dressiest: Designed with a creased leg, and heathered twill.",
        "
          <p><b>overview</b></p><ul>
          <li style='list-style: disc inside'>High-quality cotton melange pants.</li>
          <li style='list-style: disc inside'>Sits just below the waist.</li>
          <li style='list-style: disc inside'>Straight through the leg.</li>
          <li style='list-style: disc inside'>Straight leg opening.</li>
          <li style='list-style: disc inside'>Flat front, hook & bar closure, zip fly.</li>
          <li style='list-style: disc inside'>On-seam pockets, back button-welt pockets</li></ul><br />

          <p><b>fabric & care</b></p><ul>
          <li style='list-style: disc inside'>100% Cotton.</li>
          <li style='list-style: disc inside'>Machine wash.</li>
          <li style='list-style: disc inside'>Imported.</li></ul>
        "
      ]
    elsif self.style_description.strip.eql? "TAILORED RELAXED MELANGE"
      ["Our dressiest: Designed with a creased leg, and heathered twill.",
        "
          <p><b>overview</b></p><ul>
          <li style='list-style: disc inside'>High-quality cotton melange pants.</li>
          <li style='list-style: disc inside'>Sits just below the waist.</li>
          <li style='list-style: disc inside'>Full through the leg.</li>
          <li style='list-style: disc inside'>Straight leg opening.</li>
          <li style='list-style: disc inside'>Flat front, hook & bar closure, zip fly.</li>
          <li style='list-style: disc inside'>On-seam pockets, back button-welt pockets</li></ul><br />

          <p><b>fabric & care</b></p><ul>
          <li style='list-style: disc inside'>100% Cotton.</li>
          <li style='list-style: disc inside'>Machine wash.</li>
          <li style='list-style: disc inside'>Imported.</li></ul>
        "
      ]
    elsif self.style_description.strip.eql? "TAILORED STRAIGHT"
      ["Our dressiest: Designed with a creased leg, and heathered twill.",
        "
          <p><b>overview</b></p><ul>
          <li style='list-style: disc inside'>Flat front, hook & bar closure, zip fly.</li>
          <li style='list-style: disc inside'>On-seam pockets, back button-welt pockets.</li></ul><br />

          <p><b>fabric & care</b></p><ul>
          <li style='list-style: disc inside'>100% Cotton.</li>
          <li style='list-style: disc inside'>Machine wash.</li>
          <li style='list-style: disc inside'>Imported.</li></ul>
        "
      ]
    else
      ["missing","missing"]
    end
  end
end
