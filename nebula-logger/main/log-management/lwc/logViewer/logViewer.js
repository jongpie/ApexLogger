/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.                *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
 *************************************************************************************************/
import { api, LightningElement, wire } from 'lwc';
import getLog from '@salesforce/apex/Logger.getLog';

export default class LogJSONViewer extends LightningElement {
    // TODO: recordId is a reserved keyword in LWC that only works if the component has been inserted by means of Flexipage
    // onto a record page. We can rename this variable (probably) once LWC quick actions are GA'd
    @api
    logId;
    @wire(getLog, { logId: '$logId' })
    log;

    jsonCopied = false;

    get logJSON() {
        return this.log.data ? JSON.stringify(this.log.data, null, '\t') : '';
    }

    get title() {
        return this.log.data ? 'JSON for ' + this.log.data.Name : '';
    }

    get variant() {
        return this.jsonCopied ? 'success' : 'brand';
    }

    copyToClipboard() {
        const value = this.template.querySelector('pre').textContent;

        const textArea = document.createElement('textarea');
        textArea.value = value;
        // Avoid scrolling to bottom
        textArea.style.top = '0';
        textArea.style.left = '0';
        textArea.style.position = 'fixed';

        document.body.appendChild(textArea);
        textArea.focus();
        textArea.select();
        document.execCommand('copy');
        document.body.removeChild(textArea);

        // I figure it might be nice to also include the parsed JSON in the console
        console.log('Log data successfully copied to clipboard:');
        console.log(JSON.parse(value));

        this.jsonCopied = true;
    }
}
