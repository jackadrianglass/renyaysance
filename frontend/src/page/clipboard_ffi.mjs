export function copyToClipboard(text, callback) {
  navigator.clipboard.writeText(text).then(callback, callback);
}
