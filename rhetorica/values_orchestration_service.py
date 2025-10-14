"""
Values orchestration service - handles CRUD workflows and business operations.

This service coordinates between storage and business logic, returning result objects
instead of raising exceptions. Allows presentation layers (CLI, Web) to handle
success/failure cases appropriately for their context.

Written by Claude Code on 2025-10-13.
"""

from dataclasses import dataclass
from typing import Optional, List
from categoriae.values import Values, MajorValues, HighestOrderValues, LifeAreas, PriorityLevel
from rhetorica.values_storage_service import ValuesStorageService, ValuesType


@dataclass
class ValueOperationResult:
    """Result of a value operation (create, update, delete)."""
    success: bool
    value: Optional[ValuesType] = None
    error: Optional[str] = None
    error_type: str = 'unknown'  # 'validation', 'not_found', 'database', 'permission'


class ValuesOrchestrationService:
    """
    Orchestrates value CRUD operations with result objects.

    Presentation layers use this instead of directly calling storage,
    avoiding duplication of error handling logic.
    """

    def __init__(self):
        self.storage = ValuesStorageService()

    # ===== CREATE OPERATIONS =====

    def create_major_value(
        self,
        name: str,
        description: str,
        priority: int,
        life_domain: str = 'General',
        alignment_guidance: Optional[str] = None
    ) -> ValueOperationResult:
        """
        Create a major value.

        Priority validation happens in PriorityLevel constructor (domain constraint).
        This service just translates exceptions to result objects for interfaces.
        """
        try:
            value = ValuesStorageService.create_major_value(
                name=name,
                description=description,
                priority=PriorityLevel(priority),  # Domain validates here
                life_domain=life_domain,
                alignment_guidance=alignment_guidance
            )
            saved_value = self.storage.save(value)
            return ValueOperationResult(success=True, value=saved_value)
        except ValueError as e:  # Catch domain validation errors
            return ValueOperationResult(success=False, error=str(e), error_type='validation')
        except Exception as e:  # Catch storage errors
            return ValueOperationResult(success=False, error=str(e), error_type='database')

    def create_highest_order_value(
        self,
        name: str,
        description: str,
        priority: int = 1,
        life_domain: str = 'General'
    ) -> ValueOperationResult:
        """
        Create a highest order value.

        Priority validation happens in PriorityLevel constructor (domain constraint).
        """
        try:
            value = ValuesStorageService.create_highest_order_value(
                name=name,
                description=description,
                priority=PriorityLevel(priority),  # Domain validates here
                life_domain=life_domain
            )
            saved_value = self.storage.save(value)
            return ValueOperationResult(success=True, value=saved_value)
        except ValueError as e:  # Catch domain validation errors
            return ValueOperationResult(success=False, error=str(e), error_type='validation')
        except Exception as e:  # Catch storage errors
            return ValueOperationResult(success=False, error=str(e), error_type='database')

    def create_life_area(
        self,
        name: str,
        description: str,
        priority: int = 40,
        life_domain: str = 'General'
    ) -> ValueOperationResult:
        """
        Create a life area.

        Priority validation happens in PriorityLevel constructor (domain constraint).
        """
        try:
            area = ValuesStorageService.create_life_area(
                name=name,
                description=description,
                priority=PriorityLevel(priority),  # Domain validates here
                life_domain=life_domain
            )
            saved_area = self.storage.save(area)
            return ValueOperationResult(success=True, value=saved_area)
        except ValueError as e:  # Catch domain validation errors
            return ValueOperationResult(success=False, error=str(e), error_type='validation')
        except Exception as e:  # Catch storage errors
            return ValueOperationResult(success=False, error=str(e), error_type='database')

    def create_general_value(
        self,
        name: str,
        description: str,
        priority: int = 50,
        life_domain: str = 'General'
    ) -> ValueOperationResult:
        """
        Create a general value.

        Priority validation happens in PriorityLevel constructor (domain constraint).
        """
        try:
            value = ValuesStorageService.create_value(
                name=name,
                description=description,
                priority=PriorityLevel(priority),  # Domain validates here
                life_domain=life_domain
            )
            saved_value = self.storage.save(value)
            return ValueOperationResult(success=True, value=saved_value)
        except ValueError as e:  # Catch domain validation errors
            return ValueOperationResult(success=False, error=str(e), error_type='validation')
        except Exception as e:  # Catch storage errors
            return ValueOperationResult(success=False, error=str(e), error_type='database')

    # ===== READ OPERATIONS =====

    def get_all_values(
        self,
        type_filter: Optional[str] = None,
        domain_filter: Optional[str] = None
    ) -> List[ValuesType]:
        """
        Get all values with optional filtering.

        Delegates to storage layer for filtering.
        """
        return self.storage.get_all(type_filter=type_filter, domain_filter=domain_filter)

    def get_value_by_id(self, value_id: int) -> ValueOperationResult:
        """Get a single value by ID."""
        try:
            value = self.storage.get_by_id(value_id)
            if not value:
                return ValueOperationResult(
                    success=False,
                    error=f'Value with ID {value_id} not found',
                    error_type='not_found'
                )
            return ValueOperationResult(success=True, value=value)
        except Exception as e:
            return ValueOperationResult(success=False, error=str(e), error_type='database')

    # ===== UPDATE OPERATIONS =====

    def update_value(
        self,
        value_id: int,
        name: Optional[str] = None,
        description: Optional[str] = None,
        domain: Optional[str] = None,
        priority: Optional[int] = None,
        alignment_guidance: Optional[str] = None,
        notes: str = 'Updated'
    ) -> ValueOperationResult:
        """
        Update a value with validation.

        Only updates provided fields (partial update).
        Caller can provide custom notes for audit trail.
        """
        try:
            # Fetch existing value
            value = self.storage.get_by_id(value_id)
            if not value:
                return ValueOperationResult(
                    success=False,
                    error=f'Value with ID {value_id} not found',
                    error_type='not_found'
                )

            # Update fields
            if name is not None:
                value.name = name
            if description is not None:
                value.description = description
            if domain is not None:
                value.life_domain = domain
            if priority is not None:
                try:
                    value.priority = PriorityLevel(priority)
                except ValueError as e:
                    return ValueOperationResult(success=False, error=str(e), error_type='validation')

            if alignment_guidance is not None:
                # Only major values support alignment guidance
                if value.incentive_type == 'major':
                    value.alignment_guidance = alignment_guidance
                else:
                    return ValueOperationResult(
                        success=False,
                        error=f'{value.incentive_type} values do not support alignment guidance',
                        error_type='validation'
                    )

            # Save with caller-provided notes
            updated_value = self.storage.save(value, notes=notes)
            return ValueOperationResult(success=True, value=updated_value)

        except Exception as e:
            return ValueOperationResult(success=False, error=str(e), error_type='database')

    # ===== DELETE OPERATIONS =====

    def delete_value(self, value_id: int, notes: Optional[str] = None) -> ValueOperationResult:
        """
        Delete a value by ID.

        Note: Confirmation should be handled by presentation layer.
        Caller can provide custom notes for audit trail.
        """
        try:
            # Verify exists
            value = self.storage.get_by_id(value_id)
            if not value:
                return ValueOperationResult(
                    success=False,
                    error=f'Value with ID {value_id} not found',
                    error_type='not_found'
                )

            # Delete with custom or default notes
            delete_notes = notes or f'Deleted value: {value.name}'
            self.storage.delete(value_id, notes=delete_notes)
            return ValueOperationResult(success=True, value=value)

        except Exception as e:
            return ValueOperationResult(success=False, error=str(e), error_type='database')
