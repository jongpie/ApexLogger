/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.                *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
 *************************************************************************************************/

import { LightningElement, api, track, wire } from 'lwc';
import getQueryResult from '@salesforce/apex/RelatedLogEntriesController.getQueryResult';
export default class RelatedLogEntries extends LightningElement {
    @api recordId;
    @api fieldSetName;
    @api sortBy = '';
    @api sortDirection = '';
    @api rowLimit;
    @api search = '';

    @track showComponent = false;
    @track title;
    @track queryResult;

    @api
    handleSort(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
    }

    @api
    handleSearchChange(event) {
        this.search = event.target.value;
    }

    @wire(getQueryResult, {
        recordId: '$recordId',
        fieldSetName: '$fieldSetName',
        rowLimit: '$rowLimit',
        sortByFieldName: '$sortBy',
        sortDirection: '$sortDirection',
        search: '$search'
    })
    wiredLogEntries(result) {
        if (result.data) {
            let queryResult = this.processResult(result.data);

            this.queryResult = queryResult;
            this.showComponent = queryResult.isAccessible;
            this.title = queryResult.labelPlural + ' (' + queryResult.totalLogEntriesCount + ' Total)';
        } else if (result.error) {
            this.logEntryData = undefined;
            this.logEntryColumns = undefined;
            console.log(result.error);
        }
    }

    // Parse the Apex results & add any UI-specific attributes based on field metadata
    processResult(queryResult) {
        if (queryResult.fieldSet == undefined) {
            return;
        }

        queryResult = Object.assign({}, queryResult); // clone queryResult

        let fieldSet = Object.assign({}, queryResult.fieldSet); // clone fieldSet
        let fields = [].concat(queryResult.fieldSet.fields); // clone fields
        let records = [].concat(queryResult.records); // clone records

        for (let i = 0; i < fieldSet.fields.length; i++) {
            let field = Object.assign({}, fieldSet.fields[i]); // clone field

            if (field.type == 'datetime') {
                field.type = 'date';
                // FIXME and make dynamic based on user prefences for datetimes
                field.typeAttributes = {
                    month: '2-digit',
                    day: '2-digit',
                    year: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit',
                    second: '2-digit'
                };
            } else if (field.type == 'reference') {
                let displayFieldName = field.lookupDisplayFieldName.replace('.', '') + 'Display';
                let looupFieldName = field.fieldName;

                // Add URL formatting to the field
                field.type = 'url';
                field.typeAttributes = {
                    label: { fieldName: displayFieldName },
                    name: { fieldName: looupFieldName },
                    target: '_self'
                };

                // Add the link to each log entry record
                for (var j = 0; j < records.length; j++) {
                    let record = Object.assign({}, records[j]); //cloning object

                    let parentObject = record[field.relationshipName];
                    record[displayFieldName] = parentObject[field.lookupDisplayFieldName.split('.').splice(1)];
                    record[field.fieldName] = '/' + record[looupFieldName];

                    records[j] = record;
                }
            } else if (field.isNameField) {
                // Make the record's Name field a clickable link to the record
                let displayFieldName = field.fieldName + 'Display';

                // Add URL formatting to the field
                field.type = 'url';
                field.typeAttributes = {
                    label: { fieldName: displayFieldName },
                    name: { fieldName: 'Id' },
                    target: '_self'
                };

                // Add the link to each log entry record
                for (var j = 0; j < records.length; j++) {
                    let record = Object.assign({}, records[j]); //cloning object
                    record[displayFieldName] = record[field.fieldName];
                    record[field.fieldName] = '/' + record.Id;

                    records[j] = record;
                }
            }

            fields[i] = field;
        }

        queryResult.fieldSet = fieldSet;
        queryResult.fieldSet.fields = fields;
        queryResult.records = records;

        return queryResult;
    }
}
