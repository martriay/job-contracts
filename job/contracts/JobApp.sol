pragma solidity ^0.4.19;

import "@aragon/os/contracts/apps/AragonApp.sol";
import "./ENS.sol";

contract JobApp is AragonApp {

    /// Events
    event Applied(bytes32 node, string jobName);
    event Hired(bytes32 node, string jobName);
    event JobOpened(string indexed name, string description);
    event JobClosed(string indexed name, bytes32 _hiree);

    /// State
    ENS ens = ENS(0x314159265dD8dbb310642f98f50C066173C1259b);

    enum JobStatus { Open, Closed }

    struct Job {
        string description;
        JobStatus status;
        bool posted;
    }

    mapping (bytes32 => Job) internal jobs;
    mapping (bytes32 => bool) internal applications;
    mapping (bytes32 => bool) internal hired;

    /// ACL
    bytes32 constant public OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 constant public MANAGER_ROLE = keccak256("MANAGER_ROLE");

    /**
     * @notice Apply for a job by `jobName`
     * @param step Amount to increment by
     */
    function apply(bytes32 node, string jobName) external {
        require(msg.sender == nodeOwner(node));
        require(!hasBeenHired(node, jobName));
        require(jobs[keccak256(jobName)].status != JobStatus.Closed);
        applications[keccak256(node, jobName)] = true;
        Applied(node, jobName);
    }

    /**
     * @notice Open a job the counter by `step`
     * @param step Amount to decrement by
     */
    function openJob(string _name, string _description) external auth(OWNER_ROLE) {
        require(jobs[_name].posted == false);
        Job memory job = Job({
            description: _description,
            status: JobStatus.Open,
            posted: true
        });
        jobs[keccak256(_name)] = job;
        JobOpened(_name, _description);
    }

    /**
     * @notice Open a job the counter by `step`
     * @param step Amount to decrement by
     */
    function closeJob(string _name, string _node) external auth(OWNER_ROLE) {
        jobs[keccak256(_name)].status = JobStatus.Closed;
        JobClosed(_name, _node);
    }

    /**
     * @notice Apply for a job by `jobName`
     * @param step Amount to increment by
     */
    function hire(bytes32 node, string jobName) external auth(MANAGER_ROLE) {
        require(hasApplied(node, jobName));
        require(!hasBeenHired(node, jobName));
        require(jobs[keccak256(jobName)].status == JobStatus.Open);
        hired[keccak256(node, jobName)] = true;
        Hired(node, jobName);
    }

    function getJobDetails(string _name) public view returns(string, string) {
        require(jobs[_name].posted == true);
        string description = jobs[keccak256(_name)].description;
        uint8 status = jobs[keccak256(_name)].status;
        if (status == 0) {
            return (description, "Open");
        }
        if (status == 1) {
            return (description, "Closed");
        }
    }

    function hasApplied(bytes32 _node, string _job) public view returns(bool) {
        return applications[keccak256(_node, _job)];
    }

    function hasBeenHired(bytes32 _node, string _job) public view returns(bool) {
        return hired[keccak256(_node, _job)];
    }

    function nodeOwner(bytes32 _node) public view returns(address) {
        return ens.owner(_node);
    }
}
