export class FileReaderStub {
  static instances = [];

  constructor() {
    this.onload = null;
    this.result = null;
    FileReaderStub.instances.push(this);
  }

  readAsArrayBuffer(file) {
    this.file = file;
  }

  load(result) {
    this.result = result;
    this.onload();
  }
}
