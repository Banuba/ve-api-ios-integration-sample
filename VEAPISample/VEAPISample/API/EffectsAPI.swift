//
//  EffectsAPI.swift
//  VEAPISample
//
//  Created by Banuba on 11.03.22.
//

import Foundation
import VEEffectsSDK

class EffectsAPI {
  // MARK: - Singleton
  static var shared = EffectsAPI()
  
  // MARK: - Core API
  let effectApplicator: EffectApplicator
  
  init() {
    let effectsHolder = EditorEffectsConfigHolder(
      token: AppDelegate.banubaClientToken
    )
    effectApplicator = EffectApplicator(
      editor: CoreAPI.shared.coreAPI,
      effectConfigHolder: effectsHolder
    )
  }
}
