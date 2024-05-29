---
sidebar_position: 2
id: workflow_execution_code_flow
title: Workflow Execution Code Flow Diagram
---

![my image](/img/workflow_execution_code2flow.png)

### code2flow.com code

```
switch (User Interactions) {
  Create a new run => {
    goto new_run;
  }
  Cancel running workflow =>{
    `canceling` **State**;
    goto cancel_run;
  }
  Destroy existing workflow => {
    goto destroy;
  }
}

new_run:
block {
  `WorkflowExecutions\::CreateService`;
  `initial` **State**;
}


block {
  switch(**WorkflowExecutionPreparationJob**){
    User Interrupt: Cancel => {
      Job aborted;
      goto cancel_run;
    }
    Normal execution => {
    }
  }
  `WorkflowExecutions\::PreparationService`;
  `prepared` **State**
  Queue submission job;
}

block {
  wesj: {
    switch( **WorkflowExecutionSubmissionJob**) {
      Normal Execution => {
        goto wesus;
      }
      User Interrupt: Cancel => {
        Job aborted;
        goto cancel_run;
      }
      Connection Error =>{
        goto wesj;
      }
    }
  }

  wesus: {
    switch (  `WorkflowExecutions::SubmissionService`) {
      ApiExceptionError => {
        `error` **State**
        Queue cleanup job;
        goto cleanup_job;
      }
      Normal execution => {
        `submitted` **State**
        Queue status job;
        goto westj;
      }
    }
  }
}

block{
  westj: {
    switch( **WorkflowExecutionStatusJob**) {
      Normal execution => {
        goto wests;
      }
      User Interrupt: Cancel => {
        Job aborted;
        goto cancel_run;
      }
      Connection Error =>{
        goto westj;
      }
    }
  }

  wests: {
    switch (`WorkflowExecutions::StatusService`) {
      ApiExceptionError => {
        `error` **State**
        Queue cleanup job;
        goto cleanup_job;
      }
      Ga4gh `running` => {
        Queue job again;
        goto westj;
      }
      Ga4gh `error` / `canceled` => {
        `error` **State**
        Queue cleanup job;
        goto cleanup_job;
      }
      Ga4gh `completed` => {
        `completing` **State**
        Queue completion job;
        goto wecj;
      }
    }
  }
}

block {
  wecj:{
    **WorkflowExecutionCompletionJob**
  }

  wecs: {
      switch (  `WorkflowExecutions::CompletionService`) {
      Normal execution => {
        `completed` **State**
        Queue cleanup job;
        goto cleanup_job;
      }
    }
  }
}

block {
  cancel_run: {
    switch(`WorkflowExecutions::CancelService`){
      `initial` / `prepared`  **States** => {
        `canceled` **State**
        Queue cleanup job;
        goto cleanup_job;
      }
      all other **States** => {
        `canceling` **State**
        Queue cancelation job;
        goto cancelation;
      }
    }
  }
}

block {
  cancelation: {
    switch (**WorkflowExecutionCancelationJob**) {
      ApiExceptionError=>{
        switch(Run state?){
          Already completed=>{
            `canceled` **State**
            Queue cleanup job;
            goto cleanup_job;
          }
          Actual error=>{
            `error` **State**
            Queue cleanup job;
            goto cleanup_job;
          }
        }
        return;
      }
      Connection Error => {
        goto cancelation;
      }
      Normal execution => {
      }
    }
    `WorkflowExecutions\::CancelationService`;
    `canceled` **State**
    Queue cleanup job;
    goto cleanup_job;
  }
}


block {
  destroy: {
    `WorkflowExecutions\::DestroyService`;
    switch(Check if workflow execution can be destroyed){
        Check if cleaned => {
        goto cleaned;
      }
    }
    return;
  }
}

block {
  cleanup_job:{
    **WorkflowExecutionCleanupJob**;
    `WorkflowExecutions\::CleanupService`;
    Sets `cleaned` to `true`
  }
}

block {
  cleaned:
  `workflow_execution.cleaned?
}

```
