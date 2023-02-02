//
//  SensorCell.swift
//  dunlao
//
//  Created by PhilipHayes on 28/09/2022.
//

import UIKit

class SensorCell: UITableViewCell {

    @IBOutlet weak var SensorBubble: UIView!
    
    @IBOutlet weak var label: UILabel!
    
    @IBOutlet weak var rightImageView: UIImageView!
    
    @IBOutlet weak var leftImageView: UIImageView!
    
   // @IBOutlet weak var underLineLabel: UILabel!
    
    @IBOutlet weak var lblDistance: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        SensorBubble.layer.cornerRadius = SensorBubble.frame.size.height / 5
        rightImageView.tintColor = UIColor(named: K.gold)
        SensorBubble.backgroundColor = UIColor.init(named: K.beige)
        
      //  underLineLabel.alpha = 0.50
      //  leftImageView.alpha = 0.5
        
        

        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
