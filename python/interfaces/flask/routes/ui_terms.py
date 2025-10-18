"""
Terms UI routes for Ten Week Goal App.

HTML forms and pages for managing terms through a web interface.
Delegates to rhetorica (storage) for data operations.

Written by Claude Code on 2025-10-16.
"""

from flask import Blueprint, render_template, request, redirect, url_for
from datetime import datetime
from rhetorica.storage_service import TermStorageService, GoalStorageService
from categoriae.terms import GoalTerm
from ethica.term_lifecycle import get_terms_by_status, get_term_status
from config.logging_setup import get_logger

logger = get_logger(__name__)

# Create blueprint for terms UI routes
ui_terms_bp = Blueprint('ui_terms', __name__, url_prefix='/terms')


@ui_terms_bp.route('/')
def terms_home():
    """
    GET /terms - Terms home page with navigation.
    """
    return render_template('terms.html')


@ui_terms_bp.route('/list')
def terms_list():
    """
    GET /terms/list - List all terms with optional filtering.

    Query parameters:
        - status: Filter by term status ('active', 'upcoming', 'completed')
    """
    try:
        service = TermStorageService()

        # Get filter parameters
        status_filter = request.args.get('status')

        # Fetch all terms
        all_terms = service.get_all()

        # Apply status filter using ethica business logic
        if status_filter:
            terms = get_terms_by_status(all_terms, status_filter)
        else:
            terms = all_terms

        # Sort by start_date descending (most recent first)
        terms = sorted(terms, key=lambda t: t.start_date, reverse=True)

        return render_template('terms_list.html',
                             terms=terms,
                             current_status=status_filter)

    except Exception as e:
        logger.error(f"Error listing terms: {e}", exc_info=True)
        return f"Error loading terms: {e}", 500


@ui_terms_bp.route('/add', methods=['GET', 'POST'])
def terms_add():
    """
    GET /terms/add - Show form to add new term.
    POST /terms/add - Create new term from form data.
    """
    if request.method == 'GET':
        # Get all goals for selection
        try:
            goal_service = GoalStorageService()
            all_goals = goal_service.get_all()
            return render_template('terms_add.html', goals=all_goals)
        except Exception as e:
            logger.error(f"Error loading goals: {e}", exc_info=True)
            return f"Error loading form: {e}", 500

    # POST: Create new term
    try:
        service = TermStorageService()

        # Extract form data
        term_number = int(request.form.get('term_number'))
        start_date_str = request.form.get('start_date')
        target_date_str = request.form.get('target_date')  # Optional
        theme = request.form.get('theme')  # Optional

        # Parse dates
        start_date = datetime.fromisoformat(start_date_str)
        target_date = datetime.fromisoformat(target_date_str) if target_date_str else None

        # Get selected goal IDs (if any)
        goal_ids = request.form.getlist('goal_ids')
        term_goals_by_id = [int(gid) for gid in goal_ids if gid]

        # Create term object
        term = GoalTerm(
            common_name=f"Term {term_number}",
            term_number=term_number,
            start_date=start_date,
            target_date=target_date,
            description=theme if theme else f"Term {term_number}",
            term_goals_by_id=term_goals_by_id
        )

        # Save to database
        service.store_single_instance(term)

        logger.info(f"Created term {term.id}: Term {term_number}")

        return redirect(url_for('ui_terms.terms_list'))

    except Exception as e:
        logger.error(f"Error creating term: {e}", exc_info=True)
        return f"Error creating term: {e}", 500


@ui_terms_bp.route('/edit/<int:term_id>', methods=['GET', 'POST'])
def terms_edit(term_id: int):
    """
    GET /terms/edit/<id> - Show form to edit term.
    POST /terms/edit/<id> - Update term from form data.
    """
    service = TermStorageService()

    if request.method == 'GET':
        try:
            term = service.get_by_id(term_id)

            if not term:
                return f"Term {term_id} not found", 404

            # Get all goals for selection
            goal_service = GoalStorageService()
            all_goals = goal_service.get_all()

            # Calculate term status using ethica business logic
            term_status = get_term_status(term)

            return render_template('terms_edit.html',
                                 term=term,
                                 goals=all_goals,
                                 term_status=term_status)

        except Exception as e:
            logger.error(f"Error loading term {term_id}: {e}", exc_info=True)
            return f"Error loading term: {e}", 500

    # POST: Update term
    try:
        term = service.get_by_id(term_id)

        if not term:
            return f"Term {term_id} not found", 404

        # Update fields from form
        term.term_number = int(request.form.get('term_number'))

        # Update dates
        start_date_str = request.form.get('start_date')
        target_date_str = request.form.get('target_date')
        term.start_date = datetime.fromisoformat(start_date_str)
        if target_date_str:
            term.target_date = datetime.fromisoformat(target_date_str)

        # Update optional fields
        theme = request.form.get('theme')
        term.description = theme if theme else None

        reflection = request.form.get('reflection')
        term.reflection = reflection if reflection else None

        # Update goal IDs
        goal_ids = request.form.getlist('goal_ids')
        term.term_goals_by_id = [int(gid) for gid in goal_ids if gid]

        # Save updated term
        service.save(term, notes='Updated via UI')

        logger.info(f"Updated term {term_id}")

        return redirect(url_for('ui_terms.terms_list'))

    except Exception as e:
        logger.error(f"Error updating term {term_id}: {e}", exc_info=True)
        return f"Error updating term: {e}", 500


@ui_terms_bp.route('/delete/<int:term_id>', methods=['POST'])
def terms_delete(term_id: int):
    """
    POST /terms/delete/<id> - Delete term (with archiving).
    """
    try:
        service = TermStorageService()

        # Delete with archiving
        result = service.delete(term_id, notes='Deleted via UI')

        logger.info(f"Deleted term {term_id}")

        return redirect(url_for('ui_terms.terms_list'))

    except ValueError as e:
        logger.error(f"Term {term_id} not found: {e}")
        return f"Term not found: {e}", 404

    except Exception as e:
        logger.error(f"Error deleting term {term_id}: {e}", exc_info=True)
        return f"Error deleting term: {e}", 500
