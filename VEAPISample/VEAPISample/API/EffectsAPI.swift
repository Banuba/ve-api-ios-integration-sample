//
//  EffectsAPI.swift
//  VEAPISample
//
//  Created by Gleb Markin on 11.03.22.
//

import Foundation
import BanubaVideoEditorEffectsSDK

class EffectsAPI {
  // MARK: - Singleton
  static var shared = EffectsAPI()
  
  // MARK: - Core API
  let effectApplicator: EffectApplicator
  
  init() {
    let effectsHolder = EditorEffectsConfigHolder(
      token: token
    )
    effectApplicator = EffectApplicator(
      editor: CoreAPI.shared.coreAPI,
      effectConfigHolder: effectsHolder
    )
  }
}
