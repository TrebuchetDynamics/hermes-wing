import 'dart:convert';
import 'dart:typed_data';

/// Content rules for Hermes chat attachments.
///
/// Pure classification only: no widget state, no picker, no transport. The
/// composer owns the staged bytes and the error surface; this module only
/// answers what a file is and how large it may be.

/// Largest image Hermes accepts.
const maxImageAttachmentBytes = 10 * 1024 * 1024;

/// Largest UTF-8 text file Hermes accepts.
const maxTextAttachmentBytes = 256 * 1024;

const _textAttachmentExtensions = {
  'md',
  'markdown',
  'txt',
  'text',
  'log',
  'csv',
  'tsv',
  'json',
  'yaml',
  'yml',
  'toml',
  'ini',
  'env',
  'xml',
  'html',
  'htm',
  'css',
  'scss',
  'less',
  'sql',
  'sh',
  'bash',
  'zsh',
  'fish',
  'ps1',
  'py',
  'js',
  'jsx',
  'ts',
  'tsx',
  'mjs',
  'cjs',
  'dart',
  'go',
  'rs',
  'c',
  'cc',
  'cpp',
  'cxx',
  'h',
  'hpp',
  'java',
  'kt',
  'kts',
  'rb',
  'php',
  'swift',
  'scala',
  'lua',
  'r',
  'pl',
  'vue',
  'svelte',
  'dockerfile',
  'makefile',
  'gitignore',
  'editorconfig',
};

/// Whether [name]/[mimeType] describe a file the composer may read as text.
bool isTextAttachment({required String name, String? mimeType}) {
  if (mimeType?.toLowerCase().startsWith('text/') == true) return true;
  final lowerName = name.toLowerCase();
  final dot = lowerName.lastIndexOf('.');
  final extension = dot < 0 || dot == lowerName.length - 1
      ? lowerName
      : lowerName.substring(dot + 1);
  return _textAttachmentExtensions.contains(extension);
}

/// The image MIME type [bytes] start with, or null when unsupported.
///
/// Sniffs magic bytes rather than trusting a declared type or file extension.
String? supportedImageMimeType(Uint8List bytes) {
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4e &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0d &&
      bytes[5] == 0x0a &&
      bytes[6] == 0x1a &&
      bytes[7] == 0x0a) {
    return 'image/png';
  }
  if (bytes.length >= 3 &&
      bytes[0] == 0xff &&
      bytes[1] == 0xd8 &&
      bytes[2] == 0xff) {
    return 'image/jpeg';
  }
  if (bytes.length >= 6 &&
      ascii
          .decode(bytes.sublist(0, 6), allowInvalid: true)
          .startsWith('GIF8')) {
    return 'image/gif';
  }
  if (bytes.length >= 12 &&
      ascii.decode(bytes.sublist(0, 4), allowInvalid: true) == 'RIFF' &&
      ascii.decode(bytes.sublist(8, 12), allowInvalid: true) == 'WEBP') {
    return 'image/webp';
  }
  return null;
}
