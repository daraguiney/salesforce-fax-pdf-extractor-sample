import { LightningElement, api, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import init from '@salesforce/apex/FaxPdfController.init';
import requestExtraction from '@salesforce/apex/FaxPdfController.requestExtraction';
import checkStatus from '@salesforce/apex/FaxPdfController.checkStatus';

export default class PdfExtractor extends LightningElement {
  @api recordId;

  @track initLoaded = false;
  @track fileName;
  @track fileDownloadUrl;
  @track contentDocumentId;
  @track ranges = '';
  @track statusText;
  @track isBusy = false;

  async connectedCallback() {
    try {
      // Load required scripts
      await Promise.all([
        loadScript(this, 'https://cdnjs.cloudflare.com/ajax/libs/pdf-lib/1.17.1/pdf-lib.min.js'),
        loadScript(this, 'https://cdnjs.cloudflare.com/ajax/libs/FileSaver.js/2.0.5/FileSaver.min.js')
      ]);

      // Wait a brief moment to ensure scripts are initialized
      await new Promise(resolve => setTimeout(resolve, 100));

      // Now load the document
      await this.loadFaxDocument();

      // Check extraction status
      await this.checkExtractionStatus();
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error('Error in initialization:', error);
      this.showToast('Error', 'Failed to load required resources: ' + error.message, 'error');
    }
  }

  async loadFaxDocument() {
    const res = await init({ parentId: this.recordId });
    this.fileName = res.fileName;
    this.fileDownloadUrl = res.fileDownloadUrl;
    this.contentDocumentId = res.contentDocumentId;
    this.initLoaded = true;
  }

  async checkExtractionStatus() {
    if (!this.contentDocumentId || !this.ranges) return;
    const res = await checkStatus({ contentDocumentId: this.contentDocumentId, ranges: this.ranges });
    if (res && res.status) {
      this.statusText = `Status: ${res.status}`;
    }
  }

  onRangesChange(e) {
    this.ranges = e.detail.value;
  }

  async onExtract() {
    if (!this.ranges) {
      this.showToast('Validation', 'Enter page ranges (e.g., 1-2,6-7)', 'warning');
      return;
    }
    this.isBusy = true;
    try {
      const res = await requestExtraction({
        parentId: this.recordId,
        contentDocumentId: this.contentDocumentId,
        ranges: this.ranges
      });
      this.statusText = `Status: ${res.status}`;
      if (res.status === 'Queued') {
        setTimeout(() => this.checkExtractionStatus(), 1500);
      }
    } catch (e) {
      this.showToast('Error', e.body?.message || e.message, 'error');
    } finally {
      this.isBusy = false;
    }
  }

  onCheck() {
    this.checkExtractionStatus();
  }

  showToast(title, message, variant) {
    const evt = new CustomEvent('showtoast', { detail: { title, message, variant } });
    this.dispatchEvent(evt);
  }
}
