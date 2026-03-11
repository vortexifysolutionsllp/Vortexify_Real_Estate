import { createElement } from 'lwc';
import ProgrammeQuestionnaireBuilder from 'c/programmeQuestionnaireBuilder';

function flushPromises() {
    return Promise.resolve();
}

describe('c-programme-questionnaire-builder', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllTimers();
        jest.useRealTimers();
    });

    it('renders preview payload with record context', async () => {
        const element = createElement('c-programme-questionnaire-builder', {
            is: ProgrammeQuestionnaireBuilder
        });
        element.recordId = 'a011234567890123';
        element.objectApiName = 'Programme__c';
        document.body.appendChild(element);

        await flushPromises();

        expect(element.shadowRoot.textContent).toContain('Programme__c');
        expect(element.shadowRoot.textContent).toContain('a011234567890123');
    });

    it('generates preview questions from form values', async () => {
        jest.useFakeTimers();

        const element = createElement('c-programme-questionnaire-builder', {
            is: ProgrammeQuestionnaireBuilder
        });
        document.body.appendChild(element);

        element.handleInputChange({
            target: { name: 'assignmentTitle', value: 'Sales Mastery Sprint' }
        });
        element.handleInputChange({
            target: { name: 'questionCount', value: '3' }
        });
        element.handleInputChange({
            target: {
                name: 'assignmentGoal',
                value: 'Assess learner understanding of consultative sales'
            }
        });

        element.validateForm = jest.fn(() => true);
        element.handleGenerateClick();

        jest.runAllTimers();
        await flushPromises();

        expect(element.generatedQuestions).toHaveLength(3);
        expect(element.generatedQuestions[0].prompt).toContain('Sales Mastery Sprint');
    });
});
