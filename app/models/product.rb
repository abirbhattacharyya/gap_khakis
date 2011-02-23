class Product < ActiveRecord::Base
  belongs_to :user
  has_many :offers

  validates_uniqueness_of :style_num_full, :scope => [:user_id]

  def images
    Product.all(:conditions => ["style_num = ? and image_url <> ? ", self.style_num, self.image_url])
  end

  def description
    if self.style_description.strip.eql? "CLASSIC STRAIGHT KHAKI"
      ["Fit for any occasion, you'll turn to the classic khaki again, and again. Not too slouchy, not too polished, your wash-and-wear, best-foot-forward pair.",
        "<b>fabric & care</b><br />
          100% Cotton. <br />
          Machine wash.<br />
          Imported.<br /><br />

          <b>overview</b><br />
          High-quality wrinkle-resistant and fade-proof cotton khaki pants.<br />
          Sits just below the waist.<br />
          Straight through the leg.<br />
          Straight leg opening.<br />
          Flat front, button closure, zip fly.<br />
          On-seam pockets, back button-welt pockets.<br />"]
    elsif self.style_description.strip.eql? "CLASSIC RELAXED KHAKI"
      ["Fit for any occasion, you'll turn to the classic khaki again, and again. Not too slouchy, not too polished, your wash-and-wear, best-foot-forward pair.",
        "<b>fabric & care</b><br />
          100% Cotton. <br />
          Machine wash.<br />
          Imported.<br /><br />

          <b>overview</b><br />
          Soft, wrinkle-resistant and fade-proof cotton khaki pants.<br />
          Sits just below the waist.<br />
          Full through the leg.<br />
          Straight leg opening.<br />
          Flat front, button closure, zip fly.<br />
          On-seam pockets, back button-welt pockets.<br />"]
    elsif self.style_description.strip.eql? "TAILORED STRAIGHT KHAKI"
      ["Introducing our dressiest pair. Designed with a creased leg, wrinkle-resistant twill, and a hook and bar closure in place of a button.",
        "<b>fabric & care</b><br />
          100% Cotton. <br />
          Machine wash.<br />
          Imported.<br /><br />

          <b>overview</b><br />
          High-quality wrinkle-resistant and fade-proof cotton khaki pants.<br />
          Sits just below the waist.<br />
          Straight through the leg.<br />
          Straight leg opening.<br />
          Flat front, hook & bar closure, zip fly.<br />
          On-seam pockets, back button-welt pockets.<br />"]
    elsif self.style_description.strip.eql? "TAILORED RELAXED KHAKI"
      ["Introducing our dressiest pair. Designed with a creased leg, wrinkle-resistant twill, and a hook and bar closure in place of a button.",
        "<b>fabric & care</b><br />
          100% Cotton. <br />
          Machine wash.<br />
          Imported.<br /><br />

          <b>overview</b><br />
          High-quality wrinkle-resistant and fade-proof cotton khaki pants.<br />
          Sits just below the waist.<br />
          Full through the leg.<br />
          Straight leg opening.<br />
          Flat front, hook & bar closure, zip fly.<br />
          On-seam pockets, back button-welt pockets.<br />"]
    elsif self.style_description.strip.eql? "VINTAGE KHAKI"
      ["Made of soft, prewashed cotton with a relaxed fit, the vintage khaki is a T's best friend.",
        "<b>fabric & care</b><br />
          100% Cotton. <br />
          Machine wash.<br />
          Imported.<br /><br />

          <b>overview</b><br />
          High-quality prewashed woven cotton khaki pants.<br />
          Sits just below the waist.<br />
          Easy through the leg.<br />
          Straight leg opening.<br />
          Button closure, zip fly.<br />
          On-seam pockets, mini-coin welt pocket, back button-welt pockets.<br />"]
    elsif self.style_description.strip.eql? "TAILORED STRAIGHT MELANGE"
      ["missing","missing"]
    elsif self.style_description.strip.eql? "TAILORED RELAXED MELANGE"
      ["missing","missing"]
    elsif self.style_description.strip.eql? "TS NAVY STRIPE (TAILORED STRAIGHT)"
      ["missing","missing"]
    elsif self.style_description.strip.eql? "TS GREY DOT STRIPE (TAILORED STRAIGHT)"
      ["missing","missing"]
    else
      ["missing","missing"]
    end
  end
end
