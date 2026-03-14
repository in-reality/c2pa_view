import 'package:c2pa_manifest_viewer/c2pa_manifest_viewer.dart';

/// Each sample bundles a provenance tree, a human-readable label,
/// a short description, and the MIME type so the example app can
/// display them in a picker.
class SampleScenario {
  final String label;
  final String description;
  final String mimeType;
  final ProvenanceNode root;

  const SampleScenario({
    required this.label,
    required this.description,
    required this.mimeType,
    required this.root,
  });
}

// ---------------------------------------------------------------------------
// 1. Camera photo — simple, single-node, valid credentials from a camera
// ---------------------------------------------------------------------------

final cameraPhoto = SampleScenario(
  label: 'Camera Photo',
  description: 'A landscape photo taken on a Nikon Z9 with full EXIF and GPS.',
  mimeType: 'image/jpeg',
  root: ProvenanceNode(
    id: 'cam-0',
    title: 'DSC_4072.NEF.jpg',
    validationResult: const ValidationResult.valid(),
    issuer: 'Nikon Corporation',
    signedDate: DateTime(2025, 6, 21, 7, 45),
    manifestViewData: ManifestViewData(
      title: 'DSC_4072.NEF.jpg',
      validationResult: const ValidationResult.valid(),
      issuer: 'Nikon Corporation',
      signedDate: DateTime(2025, 6, 21, 7, 45),
      claimGenerator: const ClaimGeneratorDisplayInfo(
        name: 'Nikon Z9',
        version: 'V5.00',
      ),
      actions: const [
        ActionDisplayInfo(actionType: 'c2pa.created', label: 'Created'),
      ],
      exifData: ExifDisplayData(
        creator: 'Alex Rivera',
        copyright: '\u00a9 2025 Alex Rivera',
        captureDate: DateTime(2025, 6, 21, 7, 45),
        cameraMake: 'Nikon',
        cameraModel: 'Nikon Z9',
        lensMake: 'Nikon',
        lensModel: 'NIKKOR Z 24-70mm f/2.8 S',
        iso: '200',
        fNumber: '8',
        focalLength: '35',
        exposureTime: '1/500',
        width: 8256,
        height: 5504,
        latitude: 44.4280,
        longitude: -110.5885,
      ),
      producer: 'Alex Rivera',
      socialAccounts: const [
        SocialAccountDisplayInfo(
            platform: 'Instagram', url: '@alexrivera.photo'),
        SocialAccountDisplayInfo(
            platform: 'Website', url: 'https://alexrivera.photo'),
      ],
      doNotTrain: true,
    ),
  ),
);

// ---------------------------------------------------------------------------
// 2. Photoshop edit — edited file with one camera-original ingredient
// ---------------------------------------------------------------------------

final photoshopEdit = SampleScenario(
  label: 'Photoshop Edit',
  description: 'A portrait retouched in Photoshop, with the camera original '
      'as an ingredient.',
  mimeType: 'image/jpeg',
  root: ProvenanceNode(
    id: 'ps-0',
    title: 'portrait_final.jpg',
    validationResult: const ValidationResult.valid(),
    issuer: 'Adobe Photoshop',
    signedDate: DateTime(2025, 9, 3, 16, 20),
    manifestViewData: ManifestViewData(
      title: 'portrait_final.jpg',
      validationResult: const ValidationResult.valid(),
      issuer: 'Adobe Inc.',
      signedDate: DateTime(2025, 9, 3, 16, 20),
      claimGenerator: const ClaimGeneratorDisplayInfo(
        name: 'Adobe Photoshop',
        version: '26.1',
      ),
      actions: const [
        ActionDisplayInfo(actionType: 'c2pa.opened', label: 'Opened'),
        ActionDisplayInfo(
            actionType: 'c2pa.color_adjustments', label: 'Color adjustments'),
        ActionDisplayInfo(actionType: 'c2pa.filtered', label: 'Filtered'),
        ActionDisplayInfo(actionType: 'c2pa.cropped', label: 'Cropped'),
        ActionDisplayInfo(actionType: 'c2pa.resized', label: 'Resized'),
        ActionDisplayInfo(actionType: 'c2pa.published', label: 'Published'),
      ],
      ingredients: const [
        IngredientDisplayInfo(
          title: 'IMG_2041.CR3',
          format: 'image/x-canon-cr3',
          hasManifest: true,
          issuer: 'Canon Inc.',
          relationship: IngredientRelationship.parentOf,
        ),
      ],
      exifData: ExifDisplayData(
        creator: 'Priya Sharma',
        copyright: '\u00a9 2025 Priya Sharma Photography',
        captureDate: DateTime(2025, 9, 1, 14, 10),
        cameraMake: 'Canon',
        cameraModel: 'Canon EOS R5 Mark II',
        lensModel: 'RF 85mm F1.2L USM',
        iso: '100',
        fNumber: '1.4',
        focalLength: '85',
        exposureTime: '1/2000',
        width: 8192,
        height: 5464,
      ),
      producer: 'Priya Sharma',
      socialAccounts: const [
        SocialAccountDisplayInfo(
            platform: 'Behance', url: 'behance.net/priyasharma'),
      ],
    ),
    children: [
      ProvenanceNode(
        id: 'ps-0.0',
        title: 'IMG_2041.CR3',
        validationResult: const ValidationResult.valid(),
        issuer: 'Canon Inc.',
        signedDate: DateTime(2025, 9, 1, 14, 10),
        manifestViewData: ManifestViewData(
          title: 'IMG_2041.CR3',
          validationResult: const ValidationResult.valid(),
          issuer: 'Canon Inc.',
          signedDate: DateTime(2025, 9, 1, 14, 10),
          claimGenerator: const ClaimGeneratorDisplayInfo(
            name: 'Canon EOS R5 Mark II',
          ),
          actions: const [
            ActionDisplayInfo(actionType: 'c2pa.created', label: 'Created'),
          ],
          exifData: ExifDisplayData(
            creator: 'Priya Sharma',
            captureDate: DateTime(2025, 9, 1, 14, 10),
            cameraMake: 'Canon',
            cameraModel: 'Canon EOS R5 Mark II',
            lensModel: 'RF 85mm F1.2L USM',
            iso: '100',
            fNumber: '1.4',
            focalLength: '85',
            exposureTime: '1/2000',
            width: 8192,
            height: 5464,
          ),
        ),
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// 3. AI generated — single node, fully AI-generated with Midjourney
// ---------------------------------------------------------------------------

final aiGenerated = SampleScenario(
  label: 'AI Generated',
  description: 'An image fully generated by Midjourney V7 with '
      'AI content credentials.',
  mimeType: 'image/png',
  root: ProvenanceNode(
    id: 'ai-0',
    title: 'cosmic_garden_v7_upscaled.png',
    validationResult: const ValidationResult.valid(),
    issuer: 'Midjourney, Inc.',
    signedDate: DateTime(2025, 12, 5, 22, 8),
    manifestViewData: ManifestViewData(
      title: 'cosmic_garden_v7_upscaled.png',
      validationResult: const ValidationResult.valid(),
      issuer: 'Midjourney, Inc.',
      signedDate: DateTime(2025, 12, 5, 22, 8),
      claimGenerator: const ClaimGeneratorDisplayInfo(
        name: 'Midjourney',
        version: '7.0',
      ),
      generativeInfo: const GenerativeInfo(
        type: GenerativeType.aiGenerated,
        softwareAgents: ['Midjourney V7'],
      ),
      aiToolsUsed: const ['Midjourney V7'],
      actions: const [
        ActionDisplayInfo(
          actionType: 'c2pa.created',
          label: 'Created',
          isAiGenerated: true,
          softwareAgent: 'Midjourney V7',
        ),
      ],
      producer: 'Midjourney, Inc.',
      doNotTrain: false,
    ),
  ),
);

// ---------------------------------------------------------------------------
// 4. Complex composite — deep tree, multiple ingredients including AI
// ---------------------------------------------------------------------------

final complexComposite = SampleScenario(
  label: 'Complex Composite',
  description: 'A magazine cover composited from multiple sources: a camera '
      'portrait, an AI background, stock textures, and a logo.',
  mimeType: 'image/tiff',
  root: ProvenanceNode(
    id: 'cc-0',
    title: 'vogue_cover_june2026_final.tiff',
    validationResult: const ValidationResult.valid(),
    issuer: 'Adobe Photoshop',
    signedDate: DateTime(2026, 3, 10, 11, 45),
    manifestViewData: ManifestViewData(
      title: 'vogue_cover_june2026_final.tiff',
      validationResult: const ValidationResult.valid(),
      issuer: 'Adobe Inc.',
      signedDate: DateTime(2026, 3, 10, 11, 45),
      claimGenerator: const ClaimGeneratorDisplayInfo(
        name: 'Adobe Photoshop',
        version: '26.4',
      ),
      generativeInfo: const GenerativeInfo(
        type: GenerativeType.compositeWithAi,
        softwareAgents: ['Adobe Firefly', 'Stability AI SDXL'],
      ),
      aiToolsUsed: const ['Adobe Firefly', 'Stability AI SDXL'],
      actions: const [
        ActionDisplayInfo(actionType: 'c2pa.opened', label: 'Opened'),
        ActionDisplayInfo(
          actionType: 'c2pa.placed',
          label: 'Placed',
          isAiGenerated: true,
        ),
        ActionDisplayInfo(
            actionType: 'c2pa.color_adjustments', label: 'Color adjustments'),
        ActionDisplayInfo(actionType: 'c2pa.drawing', label: 'Drawing'),
        ActionDisplayInfo(actionType: 'c2pa.edited', label: 'Edited'),
        ActionDisplayInfo(actionType: 'c2pa.cropped', label: 'Cropped'),
      ],
      ingredients: const [
        IngredientDisplayInfo(
          title: 'studio_portrait.jpg',
          format: 'image/jpeg',
          hasManifest: true,
          issuer: 'Sony Corporation',
          relationship: IngredientRelationship.parentOf,
        ),
        IngredientDisplayInfo(
          title: 'firefly_gradient_bg.png',
          format: 'image/png',
          hasManifest: true,
          issuer: 'Adobe Inc.',
          relationship: IngredientRelationship.componentOf,
        ),
        IngredientDisplayInfo(
          title: 'gold_foil_texture.png',
          format: 'image/png',
          hasManifest: false,
          relationship: IngredientRelationship.componentOf,
        ),
        IngredientDisplayInfo(
          title: 'vogue_logo.svg',
          format: 'image/svg+xml',
          hasManifest: false,
          relationship: IngredientRelationship.componentOf,
        ),
      ],
      exifData: ExifDisplayData(
        creator: 'Marcus Chen',
        copyright: '\u00a9 2026 Cond\u00e9 Nast',
        width: 5100,
        height: 6600,
      ),
      producer: 'Marcus Chen / Cond\u00e9 Nast Art Dept.',
      socialAccounts: const [
        SocialAccountDisplayInfo(
            platform: 'LinkedIn', url: 'linkedin.com/in/marcuschen'),
        SocialAccountDisplayInfo(
            platform: 'Instagram', url: '@marcuschen.design'),
      ],
      doNotTrain: true,
    ),
    children: [
      ProvenanceNode(
        id: 'cc-0.0',
        title: 'studio_portrait.jpg',
        validationResult: const ValidationResult.valid(),
        issuer: 'Sony Corporation',
        signedDate: DateTime(2026, 2, 28, 10, 0),
        manifestViewData: ManifestViewData(
          title: 'studio_portrait.jpg',
          validationResult: const ValidationResult.valid(),
          issuer: 'Sony Corporation',
          signedDate: DateTime(2026, 2, 28, 10, 0),
          claimGenerator: const ClaimGeneratorDisplayInfo(
            name: 'Sony \u03b17R V',
          ),
          actions: const [
            ActionDisplayInfo(actionType: 'c2pa.created', label: 'Created'),
          ],
          exifData: ExifDisplayData(
            creator: 'Marcus Chen',
            captureDate: DateTime(2026, 2, 28, 10, 0),
            cameraMake: 'Sony',
            cameraModel: 'ILCE-7RM5',
            lensModel: 'FE 70-200mm F2.8 GM OSS II',
            iso: '320',
            fNumber: '4',
            focalLength: '105',
            exposureTime: '1/320',
            width: 9504,
            height: 6336,
            latitude: 40.7580,
            longitude: -73.9855,
          ),
        ),
        children: [
          ProvenanceNode(
            id: 'cc-0.0.0',
            title: 'studio_portrait_raw.ARW',
            validationResult: const ValidationResult.valid(),
            issuer: 'Sony Corporation',
            signedDate: DateTime(2026, 2, 28, 10, 0),
            manifestViewData: ManifestViewData(
              title: 'studio_portrait_raw.ARW',
              validationResult: const ValidationResult.valid(),
              issuer: 'Sony Corporation',
              signedDate: DateTime(2026, 2, 28, 10, 0),
              claimGenerator: const ClaimGeneratorDisplayInfo(
                name: 'Sony \u03b17R V',
              ),
              actions: const [
                ActionDisplayInfo(
                    actionType: 'c2pa.created', label: 'Created'),
              ],
            ),
          ),
        ],
      ),
      ProvenanceNode(
        id: 'cc-0.1',
        title: 'firefly_gradient_bg.png',
        validationResult: const ValidationResult.valid(),
        issuer: 'Adobe Inc.',
        signedDate: DateTime(2026, 3, 5, 15, 30),
        manifestViewData: ManifestViewData(
          title: 'firefly_gradient_bg.png',
          validationResult: const ValidationResult.valid(),
          issuer: 'Adobe Inc.',
          signedDate: DateTime(2026, 3, 5, 15, 30),
          claimGenerator: const ClaimGeneratorDisplayInfo(
            name: 'Adobe Firefly',
            version: '4.0',
          ),
          generativeInfo: const GenerativeInfo(
            type: GenerativeType.aiGenerated,
            softwareAgents: ['Adobe Firefly 4.0'],
          ),
          aiToolsUsed: const ['Adobe Firefly 4.0'],
          actions: const [
            ActionDisplayInfo(
              actionType: 'c2pa.created',
              label: 'Created',
              isAiGenerated: true,
            ),
          ],
        ),
      ),
      const ProvenanceNode(
        id: 'cc-0.2',
        title: 'gold_foil_texture.png',
        validationResult: ValidationResult.noCredential(),
      ),
      const ProvenanceNode(
        id: 'cc-0.3',
        title: 'vogue_logo.svg',
        validationResult: ValidationResult.noCredential(),
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// 5. Tampered / Invalid — file modified after signing
// ---------------------------------------------------------------------------

final tamperedFile = SampleScenario(
  label: 'Tampered File',
  description: 'A news photo whose pixels were altered after the Content '
      'Credential was signed, making it invalid.',
  mimeType: 'image/jpeg',
  root: ProvenanceNode(
    id: 'inv-0',
    title: 'reuters_protest_modified.jpg',
    validationResult:
        const ValidationResult.invalid('Asset hash mismatch detected.'),
    issuer: 'Reuters',
    signedDate: DateTime(2025, 8, 12, 18, 33),
    manifestViewData: ManifestViewData(
      title: 'reuters_protest_modified.jpg',
      validationResult:
          const ValidationResult.invalid('Asset hash mismatch detected.'),
      issuer: 'Reuters Media',
      signedDate: DateTime(2025, 8, 12, 18, 33),
      claimGenerator: const ClaimGeneratorDisplayInfo(
        name: 'Reuters Connect',
        version: '3.2',
      ),
      actions: const [
        ActionDisplayInfo(actionType: 'c2pa.created', label: 'Created'),
        ActionDisplayInfo(actionType: 'c2pa.published', label: 'Published'),
      ],
      ingredients: const [
        IngredientDisplayInfo(
          title: 'DSCF0192.RAF',
          format: 'image/x-fuji-raf',
          hasManifest: true,
          issuer: 'Fujifilm Corporation',
          relationship: IngredientRelationship.parentOf,
        ),
      ],
      exifData: ExifDisplayData(
        creator: 'Kenji Watanabe',
        copyright: '\u00a9 2025 Reuters',
        captureDate: DateTime(2025, 8, 12, 16, 5),
        cameraMake: 'Fujifilm',
        cameraModel: 'X-T5',
        lensModel: 'XF 16-55mm F2.8 R LM WR',
        iso: '800',
        fNumber: '4',
        focalLength: '23',
        exposureTime: '1/1000',
        width: 6240,
        height: 4160,
        latitude: 35.6762,
        longitude: 139.6503,
      ),
      producer: 'Reuters',
    ),
    children: [
      ProvenanceNode(
        id: 'inv-0.0',
        title: 'DSCF0192.RAF',
        validationResult: const ValidationResult.valid(),
        issuer: 'Fujifilm Corporation',
        signedDate: DateTime(2025, 8, 12, 16, 5),
        manifestViewData: ManifestViewData(
          title: 'DSCF0192.RAF',
          validationResult: const ValidationResult.valid(),
          issuer: 'Fujifilm Corporation',
          signedDate: DateTime(2025, 8, 12, 16, 5),
          claimGenerator: const ClaimGeneratorDisplayInfo(name: 'Fujifilm X-T5'),
          actions: const [
            ActionDisplayInfo(actionType: 'c2pa.created', label: 'Created'),
          ],
          exifData: ExifDisplayData(
            captureDate: DateTime(2025, 8, 12, 16, 5),
            cameraMake: 'Fujifilm',
            cameraModel: 'X-T5',
            lensModel: 'XF 16-55mm F2.8 R LM WR',
            iso: '800',
            fNumber: '4',
            focalLength: '23',
            exposureTime: '1/1000',
            width: 6240,
            height: 4160,
          ),
        ),
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// 6. Unrecognized issuer — valid signature, but unknown signer
// ---------------------------------------------------------------------------

final unrecognizedIssuer = SampleScenario(
  label: 'Unrecognized Issuer',
  description: 'An image signed with a valid but unrecognized certificate '
      'from an unknown organization.',
  mimeType: 'image/webp',
  root: ProvenanceNode(
    id: 'unk-0',
    title: 'promo_banner_q4.webp',
    validationResult: const ValidationResult.unrecognized(
        'Certificate issuer not in the known trust list.'),
    issuer: 'PixelForge Design Co.',
    signedDate: DateTime(2025, 10, 1, 9, 0),
    manifestViewData: ManifestViewData(
      title: 'promo_banner_q4.webp',
      validationResult: const ValidationResult.unrecognized(
          'Certificate issuer not in the known trust list.'),
      issuer: 'PixelForge Design Co.',
      signedDate: DateTime(2025, 10, 1, 9, 0),
      claimGenerator: const ClaimGeneratorDisplayInfo(
        name: 'PixelForge Studio',
        version: '2.1.0',
      ),
      actions: const [
        ActionDisplayInfo(actionType: 'c2pa.created', label: 'Created'),
        ActionDisplayInfo(actionType: 'c2pa.edited', label: 'Edited'),
        ActionDisplayInfo(actionType: 'c2pa.resized', label: 'Resized'),
        ActionDisplayInfo(actionType: 'c2pa.transcoded', label: 'Transcoded'),
      ],
      exifData: const ExifDisplayData(width: 2400, height: 1260),
      producer: 'PixelForge Design Co.',
      website: 'https://pixelforge.example.com',
    ),
  ),
);

// ---------------------------------------------------------------------------
// All scenarios in order
// ---------------------------------------------------------------------------

final allScenarios = <SampleScenario>[
  cameraPhoto,
  photoshopEdit,
  aiGenerated,
  complexComposite,
  tamperedFile,
  unrecognizedIssuer,
];
