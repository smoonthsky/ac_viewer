class XMP {
  static const propNamespaceSeparator = ':';
  static const structFieldSeparator = '/';

  // cf https://exiftool.org/TagNames/XMP.html
  static const Map<String, String> namespaces = {
    'acdsee': 'ACDSee',
    'adsml-at': 'AdsML',
    'aux': 'Exif Aux',
    'avm': 'Astronomy Visualization',
    'Camera': 'Camera',
    'cc': 'Creative Commons',
    'crd': 'Camera Raw Defaults',
    'creatorAtom': 'After Effects',
    'crs': 'Camera Raw Settings',
    'dc': 'Dublin Core',
    'drone-dji': 'DJI Drone',
    'dwc': 'Darwin Core',
    'exif': 'Exif',
    'exifEX': 'Exif Ex',
    'GettyImagesGIFT': 'Getty Images',
    'GAudio': 'Google Audio',
    'GDepth': 'Google Depth',
    'GImage': 'Google Image',
    'GIMP': 'GIMP',
    'GCamera': 'Google Camera',
    'GCreations': 'Google Creations',
    'GFocus': 'Google Focus',
    'GPano': 'Google Panorama',
    'illustrator': 'Illustrator',
    'Iptc4xmpCore': 'IPTC Core',
    'Iptc4xmpExt': 'IPTC Extension',
    'lr': 'Lightroom',
    'MicrosoftPhoto': 'Microsoft Photo',
    'mwg-rs': 'Regions',
    'panorama': 'Panorama',
    'PanoStudioXMP': 'PanoramaStudio',
    'pdf': 'PDF',
    'pdfx': 'PDF/X',
    'photomechanic': 'Photo Mechanic',
    'photoshop': 'Photoshop',
    'plus': 'PLUS',
    'pmtm': 'Photomatix',
    'tiff': 'TIFF',
    'xmp': 'Basic',
    'xmpBJ': 'Basic Job Ticket',
    'xmpDM': 'Dynamic Media',
    'xmpMM': 'Media Management',
    'xmpRights': 'Rights Management',
    'xmpTPg': 'Paged-Text',
  };
}
