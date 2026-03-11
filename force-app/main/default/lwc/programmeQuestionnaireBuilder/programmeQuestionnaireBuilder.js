import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const QUESTION_TYPE_LABELS = {
    mcq: 'MCQ',
    shortAnswer: 'Short Answer',
    caseStudy: 'Case Study',
    mixed: 'Mixed'
};

export default class ProgrammeQuestionnaireBuilder extends LightningElement {
    @api recordId;
    @api objectApiName;

    @track form = {
        assignmentTitle: '',
        assignmentGoal: '',
        learnerLevel: 'intermediate',
        questionType: 'mixed',
        questionCount: 5,
        durationMinutes: 30,
        evaluationFocus: 'conceptual_clarity'
    };

    @track generatedQuestions = [];
    @track currentStep = 1;
    isGenerating = false;
    generateTimeout;

    learnerLevelOptions = [
        { label: 'Beginner', value: 'beginner' },
        { label: 'Intermediate', value: 'intermediate' },
        { label: 'Advanced', value: 'advanced' }
    ];

    questionTypeOptions = [
        { label: 'Mixed', value: 'mixed' },
        { label: 'MCQ', value: 'mcq' },
        { label: 'Short Answer', value: 'shortAnswer' },
        { label: 'Case Study', value: 'caseStudy' }
    ];

    evaluationFocusOptions = [
        { label: 'Conceptual Clarity', value: 'conceptual_clarity' },
        { label: 'Application Skills', value: 'application_skills' },
        { label: 'Problem Solving', value: 'problem_solving' },
        { label: 'Communication', value: 'communication' }
    ];

    handleInputChange(event) {
        const { name, value } = event.target;

        this.form = {
            ...this.form,
            [name]:
                name === 'questionCount' || name === 'durationMinutes'
                    ? Number(value)
                    : value
        };
    }

    handleNext() {
        if (this.currentStep === 1) {
            this.generateQuestions();
            return;
        }

        if (this.currentStep === 2) {
            this.currentStep = 3;
            return;
        }

        this.currentStep = 1;
    }

    handleBack() {
        if (this.currentStep > 1) {
            this.currentStep -= 1;
        }
    }

    generateQuestions() {
        if (!this.validateStepOne()) {
            return;
        }

        this.isGenerating = true;

        window.clearTimeout(this.generateTimeout);
        this.generateTimeout = window.setTimeout(() => {
            this.generatedQuestions = this.buildPreviewQuestions();
            this.currentStep = 2;
            this.isGenerating = false;

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Questions ready',
                    message: 'The questionnaire has been prepared for review.',
                    variant: 'success'
                })
            );
        }, 500);
    }

    disconnectedCallback() {
        window.clearTimeout(this.generateTimeout);
    }

    handleReset() {
        this.form = {
            assignmentTitle: '',
            assignmentGoal: '',
            learnerLevel: 'intermediate',
            questionType: 'mixed',
            questionCount: 5,
            durationMinutes: 30,
            evaluationFocus: 'conceptual_clarity'
        };
        this.generatedQuestions = [];
        this.currentStep = 1;
    }

    validateStepOne() {
        const inputs = [
            ...this.template.querySelectorAll(
                'lightning-input, lightning-textarea, lightning-combobox'
            )
        ];
        const isValid = inputs.reduce(
            (valid, input) => input.reportValidity() && valid,
            true
        );

        if (!isValid) {
            return false;
        }

        if (this.form.questionCount < 1 || this.form.questionCount > 20) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Invalid question count',
                    message: 'Question count must be between 1 and 20.',
                    variant: 'error'
                })
            );
            return false;
        }

        return true;
    }

    buildPreviewQuestions() {
        return Array.from({ length: this.form.questionCount }, (_, index) => {
            const questionNumber = index + 1;
            const type = this.resolveQuestionType(questionNumber);

            return {
                id: `q-${questionNumber}`,
                number: questionNumber,
                typeLabel: QUESTION_TYPE_LABELS[type],
                sectionLabel: `Question ${questionNumber}`,
                prompt: this.buildPrompt(type, questionNumber),
                rubric: this.buildRubric(type),
                options: type === 'mcq' ? this.buildMcqOptions(questionNumber) : []
            };
        });
    }

    resolveQuestionType(questionNumber) {
        if (this.form.questionType !== 'mixed') {
            return this.form.questionType;
        }

        const rotation = ['mcq', 'shortAnswer', 'caseStudy'];
        return rotation[(questionNumber - 1) % rotation.length];
    }

    buildPrompt(type, questionNumber) {
        const title = this.form.assignmentTitle || 'Programme assignment';
        const goal =
            this.form.assignmentGoal ||
            'Demonstrate understanding of the programme topic';

        if (type === 'mcq') {
            return `Which option best supports the goal "${goal}" for "${title}"?`;
        }

        if (type === 'caseStudy') {
            return `Review a learner scenario for "${title}" and explain how you would apply the programme concepts to reach an outcome.`;
        }

        return `In your own words, explain how "${title}" helps achieve "${goal}".`;
    }

    buildRubric(type) {
        if (type === 'mcq') {
            return 'Score based on correctness and reasoning confidence.';
        }

        if (type === 'caseStudy') {
            return 'Score based on structure, relevance, and practical application.';
        }

        return 'Score based on clarity, completeness, and conceptual understanding.';
    }

    buildMcqOptions(questionNumber) {
        return ['A', 'B', 'C', 'D'].map((option) => ({
            id: `${questionNumber}-${option}`,
            label: `Option ${option}`
        }));
    }

    get recordContextLabel() {
        if (!this.recordId) {
            return 'Standalone preview';
        }

        return `${this.objectApiName || 'Record'} | ${this.recordId}`;
    }

    get questionnaireSummary() {
        return `${this.form.questionCount} questions | ${
            QUESTION_TYPE_LABELS[this.form.questionType] || 'Mixed'
        } | ${this.form.durationMinutes} mins`;
    }

    get assignmentHeading() {
        return this.form.assignmentTitle || 'Assignment Questionnaire';
    }

    get assignmentInstructions() {
        return (
            this.form.assignmentGoal ||
            'Complete all questions in sequence and answer based on your understanding of the programme.'
        );
    }

    get learnerLevelLabel() {
        return this.learnerLevelOptions.find(
            (option) => option.value === this.form.learnerLevel
        )?.label;
    }

    get evaluationFocusLabel() {
        return this.evaluationFocusOptions.find(
            (option) => option.value === this.form.evaluationFocus
        )?.label;
    }

    get steps() {
        return [
            { id: 1, label: 'Assignment Details', className: this.getStepClass(1) },
            { id: 2, label: 'Questionnaire', className: this.getStepClass(2) },
            { id: 3, label: 'Review Criteria', className: this.getStepClass(3) }
        ];
    }

    get isStepOne() {
        return this.currentStep === 1;
    }

    get isStepTwo() {
        return this.currentStep === 2;
    }

    get isStepThree() {
        return this.currentStep === 3;
    }

    get showResetButton() {
        return this.currentStep === 1;
    }

    get disableBack() {
        return this.currentStep === 1 || this.isGenerating;
    }

    get nextLabel() {
        if (this.currentStep === 1) {
            return 'Next';
        }

        if (this.currentStep === 2) {
            return 'Next';
        }

        return 'Start Over';
    }

    getStepClass(stepNumber) {
        if (this.currentStep === stepNumber) {
            return 'step-pill active';
        }

        if (this.currentStep > stepNumber) {
            return 'step-pill completed';
        }

        return 'step-pill';
    }
}
